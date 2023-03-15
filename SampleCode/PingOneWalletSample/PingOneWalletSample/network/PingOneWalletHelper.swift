//
//  PingOneWalletHelper.swift
//  PingOneWalletSample
//
//

import Foundation
import PingOneWallet
import DIDSDK
import UIKit

class PingOneWalletHelper {
    
    static func initializeWallet(_ storageManager: StorageManagerContract?) -> CompletionHandler<Bool> {
        let completionHandler = CompletionHandler<Bool>()
        if let _ = shared {
            completionHandler.setResult(true)
            return completionHandler
        }
        
        let clientBuilder = PingOneWalletClient.Builder()
        if let storageManager = storageManager {
            clientBuilder.setStorageManager(storageManager)
        }
        clientBuilder.build()
            .onError { error in
                completionHandler.setError(error)
            }
            .onResult { client in
                shared = PingOneWalletHelper(client, storageManager: storageManager)
                completionHandler.setResult(true)
            }
        
        return completionHandler
    }
    
    public static var shared: PingOneWalletHelper!
    
    private var pingoneWalletClient: PingOneWalletClient!
    
    private init(_ pingoneWalletClient: PingOneWalletClient, storageManager: StorageManagerContract?) {
        self.pingoneWalletClient = pingoneWalletClient
        self.pingoneWalletClient.registerCallbackHandler(self)
        if let storageManager = storageManager {
            self.pingoneWalletClient.registerStorageManager(storageManager)
        }
        DataRepository.shared.storageManager.saveApplicationInstance(pingoneWalletClient.getApplicationInstance())
    }
    
    public func updatePushToken(_ pushToken: String) {
        DataRepository.shared.storageManager.saveApplicationInstance(self.pingoneWalletClient.updatePushToken(pushToken))
    }
    
    func processQrContent(_ qrContent: String) {
        self.pingoneWalletClient.processQrContent(qrContent)
            
    }
    
    public func reportCredentialDeletion(_ claim: Claim) {
        self.pingoneWalletClient.reportCredentialDeletion(claim: claim)
    }
}

extension PingOneWalletHelper: WalletCallbackHandler {
    
    func handleCredentialIssuance(issuer: String, message: String?, challenge: Challenge?, claim: Claim, errors: [PingOneWallet.WalletException]) -> Bool {
        logattention("Credential received: Issuer: \(issuer), message: \(message ?? "none")")
        NotificationUtils.showToast(message: "Received a new credential")
        DataRepository.shared.saveClaim(claim)
        EventObserverUtils.broadcastClaimsUpdatedNotification()
        return true
    }
    
    func handleCredentialRevocation(issuer: String, message: String?, challenge: Challenge?, claimReference: ClaimReference, errors: [PingOneWallet.WalletException]) -> Bool {
        logattention("Credential revoked: Issuer: \(issuer), message: \(message ?? "none")")
        NotificationUtils.showToast(message: "Credential Revoked")
        DataRepository.shared.saveRevokedClaimReference(claimReference)
        EventObserverUtils.broadcastClaimsUpdatedNotification()
        return true
    }
    
    func handleCredentialPresentation(sender: String, message: String?, challenge: Challenge?, claim: [Share], errors: [PingOneWallet.WalletException]) {
        //TODO: handle peer to peer Credential Presentation
    }
    
    func handleCredentialRequest(_ presentationRequest: PresentationRequest) {
        guard !self.handlePairingRequest(presentationRequest) else {
            return
        }
        
        NotificationUtils.showToast(message: "Processing presentation request...", duration: 2.0)
        
        let allClaims = DataRepository.shared.getAllClaims()
        let credentialMatcherResults = self.pingoneWalletClient.findMatchingCredentialsForRequest(presentationRequest, credentials: allClaims).getResult()
        
        var matchingCredentials: Bool = false
        for credentialMatcherResult in credentialMatcherResults {
            if !(credentialMatcherResult.claims.isEmpty) {
                matchingCredentials = true
                break
            }
        }
        
        guard matchingCredentials else {
            NotificationUtils.showErrorAlert(title: "No matching credentials", message: "Cannot find any credentials in your wallet matching the criteria in the request.")
            return
        }
        
        let pickerEventHandler = PickerEventHandler(for: presentationRequest) { result in
            guard let result = result, !result.isEmpty() else {
                logattention("Action canceled by user.")
                NotificationUtils.showToast(message: "Presentation canceled", duration: 2.0)
                return
            }
            
            self.shareCredentialPresentation(result)
        }
        
        self.selectCredentialToPresent(credentialMatcherResults, index: 0, listener: pickerEventHandler)
        
    }
    
    func handleError(_ error: PingOneWallet.WalletException) {
        switch error {
        case .cannotProcessUrl(let url, let debugDescription):
            logerror("Failed to process url: \(url) - \(debugDescription ?? "None")")
            NotificationUtils.showToast(message: "Failed to process request", duration: 2.0)
        default:
            logerror("Error in wallet callback handler: \(error.localizedDescription)")
        }
    }
    
    private func handlePairingRequest(_ presentationRequest: PresentationRequest) -> Bool {
        guard (presentationRequest.isPairingRequest()) else {
            return false
        }
        NotificationUtils.showConfirmationAlert(title: "Pair Wallet", message: "Please confirm to pair your wallet to receive a credential.") { isPositiveAction, alertVc in
            if (isPositiveAction) {
                self.pingoneWalletClient.pairWallet(for: presentationRequest)
                    .onResult({ _ in
                        logattention("Wallet pairing successful")
                        NotificationUtils.showToast(message: "Wallet pairing successful")
                    })
                    .onError { err in
                        logerror("Wallet pairing failed: \(err.localizedDescription)")
                        NotificationUtils.showToast(message: "Wallet pairing failed")
                    }
            }
        }
        return true
    }
    
    private func selectCredentialToPresent(_ credentialMatcherResults: [CredentialMatcherResult], index: Int, listener: ClaimPickerListener) {
        guard (index < credentialMatcherResults.count) else {
            listener.onPickerComplete()
            return
        }
        
        let credentialMatcherResult = credentialMatcherResults[index]
        guard credentialMatcherResult.claims.count > 0 else {
            self.selectCredentialToPresent(credentialMatcherResults, index: index + 1, listener: listener)
            return
        }
        
        if (credentialMatcherResult.claims.count == 1) {
            listener.onClaimPicked(credentialMatcherResult.claims[0], keys: credentialMatcherResult.requestedKeys)
            self.selectCredentialToPresent(credentialMatcherResults, index: index + 1, listener: listener)
        } else {
            NotificationUtils.showClaimsPicker(credentialMatcherResult.claims) { selectedClaim in
                guard let claim = selectedClaim else {
                    listener.onPickerCanceled()
                    return
                }
                listener.onClaimPicked(claim, keys: credentialMatcherResult.requestedKeys)
                self.selectCredentialToPresent(credentialMatcherResults, index: index + 1, listener: listener)
            }
        }
    }
    
    
    
    private func shareSelfClaim(_ presentationRequest: PresentationRequest) {
        let credentialPresentation = CredentialsPresentation(presentationRequest: presentationRequest)
        if let selfClaim = DataRepository.shared.getSelfClaim() {
            self.shareCredentialPresentation(credentialPresentation.addClaimForKeys(selfClaim, keys: presentationRequest.getStringKeys()))
        } else {
            let map = (try? DataRepository.shared.getProfile()?.toDictionary()) ?? [:]
            self.pingoneWalletClient.createSelfClaim(map)
                .onError { logerror("Failed to create self-claim...share data: \($0.localizedDescription)") }
                .onResult { selfClaim in
                    DataRepository.shared.saveSelfClaim(selfClaim)
                    self.shareCredentialPresentation(credentialPresentation.addClaimForKeys(selfClaim, keys: presentationRequest.getStringKeys()))
                }
        }
    }
    
    private func shareCredentialPresentation(_ credentialPresentation: CredentialsPresentation) {
        self.pingoneWalletClient.presentCredentials(credentialPresentation)
            .onResult { result in
                switch result.getPresentationStatus() {
                case .success:
                    NotificationUtils.showToast(message: "Information sent successfully")
                case .failure:
                    logerror("Error sharing information: \(result.getDetails()?.debugDescription ?? "None")")
                    NotificationUtils.showToast(message: "Failed to present credential")
                case .requiresAction(let action):
                    self.handlePresentationAction(action)
                }
            }
            .onError { err in
                logerror("Error sharing information: \(err.localizedDescription)")
                NotificationUtils.showToast(message: "Failed to present credential")
            }
    }
    
    private func handlePresentationAction(_ action: PresentationAction) {
        switch action {
        case .openUri(let redirectUri):
            guard let redirectUri = URL(string: redirectUri),
                  UIApplication.shared.canOpenURL(redirectUri) else {
                logerror("Failed to parse URL: \(redirectUri)")
                NotificationUtils.showToast(message: "Failed to process request")
                return
            }
            
            UIApplication.shared.open(redirectUri) { result in
                logattention("Opening URL: \(redirectUri) - result: \(result)")
                NotificationUtils.showToast(message: result ? "Presentation request processed" : "Failed to process request")
            }
        }
    }
    
}

class PickerEventHandler: ClaimPickerListener {
    
    var result: CredentialsPresentation
    var onEvent: ((CredentialsPresentation?) -> Void)!
    
    init(for presentationRequest: PresentationRequest, onEvent: @escaping (CredentialsPresentation?) -> Void) {
        self.result = CredentialsPresentation(presentationRequest: presentationRequest)
        self.onEvent = onEvent
    }
    
    func onClaimPicked(_ claim: Claim, keys: [String]) {
        self.result.addClaimForKeys(claim, keys: keys)
    }
    
    func onPickerComplete() {
        self.onEvent(self.result)
    }
    
    func onPickerCanceled() {
        self.onEvent(nil)
    }
    
}
