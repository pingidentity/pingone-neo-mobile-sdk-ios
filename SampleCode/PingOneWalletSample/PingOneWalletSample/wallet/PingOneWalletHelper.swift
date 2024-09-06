//
//  PingOneWalletHelper.swift
//  PingOneWalletSample
//
//

import UIKit
import Foundation
import PingOneWallet
import DIDSDK

public class PingOneWalletHelper {
    
    static func initializeWallet() -> CompletionHandler<PingOneWalletHelper> {
        let completionHandler = CompletionHandler<PingOneWalletHelper>()
        
        let clientBuilder = PingOneWalletClient.Builder(forRegion: PingOneRegion.NA) // Defaulting to initializing for NA
        clientBuilder.build()
            .onError { error in
                completionHandler.setError(error)
            }
            .onResult { client in
                let helper = PingOneWalletHelper(client)
                completionHandler.setResult(helper)
            }
        
        return completionHandler
    }
        
    static let TOAST_DURATION: TimeInterval = 2.0
    static let LaunchOptionsUserActivityKey: String = "UIApplicationLaunchOptionsUserActivityKey"
    
    private let pingoneWalletClient: PingOneWalletClient!
    private var applicationUiCallbackHandler: ApplicationUiCallbackHandler?
    private var credentialPicker: CredentialPicker?
    
    /// Set this to true if push notifications are not configured in your app
    public var enablePolling: Bool = true
    
    init(_ pingoneWalletClient: PingOneWalletClient) {
        self.pingoneWalletClient = pingoneWalletClient
        self.pingoneWalletClient.registerCallbackHandler(self)
        
        if (self.enablePolling) {
            self.pollForMessages()
        }
    }
    
    
    /// Returns boolean indicating if Wallet SDK should poll for messages
    /// - Returns: Boolean
    public func isPollingEnabled() -> Bool {
        return self.enablePolling
    }
    
    /// Call this method to start polling for new messages sent to the wallet. Use this method only if you are not using push notifications.
    public func pollForMessages() {
        self.pingoneWalletClient.pollForMessages()
    }
    
    /// Call this method to stop polling for messages sent to the wallet.
    public func stopPolling() {
        self.pingoneWalletClient.stopPolling()
    }
    
    /// Set optional ApplicationUiCallbackHandler to handle UI notifications/Alerts etc. See protocol ApplicationUiCallbackHandler for more details.
    /// - Parameter applicationUiCallbackHandler: Implementation of protocol ApplicationUiCallbackHandler
    public func setApplicationUiCallbackHandler(_ applicationUiCallbackHandler: ApplicationUiCallbackHandler) {
        self.applicationUiCallbackHandler = applicationUiCallbackHandler
    }
    
    /// Set optional CredentialPicker implementation to handle credential selection when multiple credentials of same type are present in the wallet matching the criteria in the presentation request.
    /// - Parameter credentialPicker: Implementation of protocol CredentialPicker
    public func setCredentialPicker(_ credentialPicker: CredentialPicker) {
        self.credentialPicker = credentialPicker
    }
    
    /// Set the push token for the device to be able to receive push notifications.
    /// - Parameter pushToken: Push Token
    public func updatePushToken(_ pushToken: Data) {
        self.pingoneWalletClient.updatePushTokens(pushToken)
    }
    
    /// Call this method to handle the cases where app is opened by clocking on a URL or push notification.
    /// - Parameter launchOptions: LaunchOptions
    func processLaunchOptions(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if let userActivityDict = launchOptions?[UIApplication.LaunchOptionsKey.userActivityDictionary] as? [String: Any],
           let userActivity = userActivityDict[PingOneWalletHelper.LaunchOptionsUserActivityKey] as? NSUserActivity,
           let appOpenUrl = userActivity.webpageURL?.absoluteString {
            self.processPingOneRequest(appOpenUrl)
        } else if let dict = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            self.processPingOneNotification(dict)
        }
    }
    
    /// Call this method to process PingOne Credentials QR codes and Universal links.
    /// - Parameter qrContent: Content of the scanned QR code or Universal link used to open the app
    func processPingOneRequest(_ qrContent: String) {
        self.pingoneWalletClient.processPingOneRequest(qrContent)
    }
    
    /// Call this method to process the notification received by the app.
    /// - Parameter userInfo: userInfo dictionary in the notification payload
    func processPingOneNotification(_ userInfo: [AnyHashable: Any]?) {
        if (self.pingoneWalletClient.processNotification(userInfo)) {
            logattention("Processing notification...")
        } else {
            // Mark: Handle App notification here
            logattention("Handle App notification here...")
        }
    }
    
    /// Call this method to check if wallet has received any new messages in the mailbox. This method can be used to check for messages on user action or if push notifications are not available.
    public func checkForMessages() {
        self.pingoneWalletClient.checkForMessages()
    }
    
    /// Call this method when a credential is deleted from the Wallet. Reporting this action will help admins view accurate stats on their dashboards in future.
    /// - Parameter credential: Deleted credential
    public func reportCredentialDeletion(_ credential: Claim) {
        self.pingoneWalletClient.reportCredentialDeletion(claim: credential)
    }
    
    /// This method returns the data repository used by the wallet for storing ApplicationInstances and Credentials. See DataRepository for more details.
    /// - Returns: DataRepositoiry used by Wallet instance
    public func getDataRepository() -> DataRepository {
        return self.pingoneWalletClient.getDataRepository()
    }
    
}

/// Extension to implement WalletCallbackHandler
extension PingOneWalletHelper: WalletCallbackHandler {
    
    /// Handle the newly issued credential.
    /// - Parameters:
    ///   - issuer: ApplicationInstanceID of the credential issuer
    ///   - message: Optional string message
    ///   - challenge: Optional challenge
    ///   - claim: Issued credential
    ///   - errors: List of any errors while processing/verifying the credential
    /// - Returns: True if the user has accepted the credential, False if the user has rejected the credential
    public func handleCredentialIssuance(issuer: String, message: String?, challenge: Challenge?, claim: Claim, errors: [PingOneWallet.WalletException]) -> Bool {
        logattention("Credential received: Issuer: \(issuer), message: \(message ?? "none")")
        self.notifyUser(message: "Received a new credential")
        EventObserverUtils.broadcastCredentialsUpdatedNotification(delayBy: 1)
        return true
    }
    
    /// Handle the revocation of a credential.
    /// - Parameters:
    ///   - issuer: ApplicationInstanceID of the credential issuer
    ///   - message: Optional string message
    ///   - challenge: Optional challenge
    ///   - claimReference: ClaimReference for the revoked credential
    ///   - errors: List of any errors that occurred while revoking the credential
    /// - Returns: True if the user has accepted the credential revocation, False if the user has rejected the credential revocation
    public func handleCredentialRevocation(issuer: String, message: String?, challenge: Challenge?, claimReference: ClaimReference, errors: [PingOneWallet.WalletException]) -> Bool {
        logattention("Credential revoked: Issuer: \(issuer), message: \(message ?? "none")")
        self.notifyUser(message: "Credential Revoked")
        EventObserverUtils.broadcastCredentialsUpdatedNotification(delayBy: 1)
        return true
    }
    
    /// This callback is triggered when another wallet shares a credential with the current application instance.
    /// - Parameters:
    ///   - sender: ApplicationInstanceID of the sender
    ///   - message: Optional string message
    ///   - challenge: Optional challenge
    ///   - claim: Shared credential
    ///   - errors: List of any errors that occurred while verifying the shared credential
    public func handleCredentialPresentation(sender: String, message: String?, challenge: Challenge?, claim: [Share], errors: [PingOneWallet.WalletException]) {
        //MARK: handle peer to peer Credential Presentation using native protocols
    }
    
    /// This callback is triggered when a credential is requested from the current wallet using supported protocols.
    /// - Parameter presentationRequest: PresentationRequest object for requesting Credentials from Wallet
    public func handleCredentialRequest(_ presentationRequest: PresentationRequest) {
        if (presentationRequest.isPairingRequest()) {
            self.handlePairingRequest(presentationRequest)
            return
        }
        
        self.notifyUser(message: "Processing presentation request...")
        
        let credentialMatcherResults = self.pingoneWalletClient.findMatchingCredentialsForRequest(presentationRequest).getResult()
        let matchingCredentials = credentialMatcherResults.filter { !$0.claims.isEmpty }
        
        guard !matchingCredentials.isEmpty else {
            self.showError(title: "No matching credentials", message: "Cannot find any credentials in your wallet matching the criteria in the request.")
            return
        }
        
        let message: String = matchingCredentials.count == credentialMatcherResults.count ? "Please confirm to present the requested credentials from your wallet." : "You wallet does not have all the requested credentials. Would you like to share partial information?"
        let title: String = matchingCredentials.count == credentialMatcherResults.count ? "Share Information" : "Missing Credentials"
        
        self.askUserPermission(title: title , message: message) { isPositiveAction in
            if (isPositiveAction) {
                self.selectCredential(presentationRequest, credentialMatcherResults: credentialMatcherResults)
            } else {
                self.notifyUser(message: "Presentation canceled")
            }
        }
    }
    
    private func selectCredential(_ presentationRequest: PresentationRequest, credentialMatcherResults: [CredentialMatcherResult]) {
        self.credentialPicker?.selectCredentialFor(presentationRequest: presentationRequest, credentialMatcherResults: credentialMatcherResults, onResult: { result in
            guard let result = result, !result.isEmpty() else {
                self.notifyUser(message: "Presentation canceled")
                return
            }
            
            self.shareCredentialPresentation(result)
        })
    }
    
    /// Callback returns different events while using Wallet, including errors
    /// Backward compatibility - Call super.handleEvent() if you're still using `handleError` callback to manage exceptions.
    /// - Parameter event: WalletEvent
    public func handleEvent(_ event: WalletEvent) {
        switch event {
        case let event as WalletPairingEvent:
            self.handlePairingEvent(event)
        case let event as WalletCredentialEvent:
            self.handleCredentialEvent(event)
        case let event as WalletError:
            self.handleErrorEvent(event)
        default:
            logattention("Received unknown event. \(event.getType())")
        }
    }
    
}

/// Extension to manage UI notifications, alerts etc, override implementation to change default behavior
extension PingOneWalletHelper {
    
    private func handlePairingEvent(_ event: WalletPairingEvent) {
        switch event.getPairingEventType() {
        case .PAIRING_REQUEST:
            self.handlePairingRequest(event.getPairingRequest())
        case .PAIRING_RESPONSE:
            logattention("Wallet paired: \(String(describing: event.isSuccess())) - error: \(event.getError()?.localizedDescription ?? "None")")
            if let isSuccess = event.isSuccess() {
                self.notifyUser(message: isSuccess ? "Wallet paired successfully" : "Wallet pairing failed")
            }
        }
    }
    
    private func handlePairingRequest(_ pairingRequest: PairingRequest) {
        self.askUserPermission(title: "Pair Wallet", message: "Please confirm to pair your wallet to receive a credential.") { isPositiveAction in
            guard (isPositiveAction) else {
                logattention("Pairing canceled by user")
                return
            }
            self.pingoneWalletClient.pairWallet(for: pairingRequest)
                .onResult({ _ in
                    self.notifyUser(message: "Pairing wallet...")
                })
                .onError { err in
                    logerror("Wallet pairing failed: \(err.localizedDescription)")
                    self.notifyUser(message: "Wallet pairing failed")
                }
        }
    }
    
    private func handlePairingRequest(_ presentationRequest: PresentationRequest) {
        guard let pairingRequest = presentationRequest.getPairingRequest() else {
            logerror("Wallet pairing failed: Invalid request for pairing")
            self.notifyUser(message: "Wallet pairing failed")
            return
        }
        self.handlePairingRequest(pairingRequest)
    }
    
    private func shareCredentialPresentation(_ credentialPresentation: CredentialsPresentation) {
        self.presentCredential(credentialPresentation)
    }
    
    private func presentCredential(_ credentialPresentation: CredentialsPresentation) {
        self.pingoneWalletClient.presentCredentials(credentialPresentation)
            .onResult { result in
                switch result.getPresentationStatus() {
                case .success:
                    self.notifyUser(message: "Information sent successfully")
                case .failure:
                    logerror("Error sharing information: \(result.getDetails()?.debugDescription ?? "None")")
                    self.notifyUser(message: "Failed to present credential")
                case .requiresAction(let action):
                    self.handlePresentationAction(action)
                }
            }
            .onError { err in
                logerror("Error sharing information: \(err.localizedDescription)")
                self.notifyUser(message: "Failed to present credential")
            }
    }
    
    private func handlePresentationAction(_ action: PresentationAction) {
        switch action {
        case .openUri(let redirectUri):
            self.applicationUiCallbackHandler?.openUrl(url: redirectUri, onComplete: { result, message in
                logattention("Opening URL: \(redirectUri) - result: \(result) - message: \(message)")
                self.notifyUser(message: message)
            })
        }
    }
    
    private func handleErrorEvent(_ errorEvent: WalletError) {
        switch errorEvent.getError() {
        case .cannotProcessUrl(let url, let debugDescription):
            logerror("Failed to process url: \(url) - \(debugDescription ?? "None")")
            self.notifyUser(message: "Failed to process request")
        default:
            logerror("Error in wallet callback handler: \(errorEvent.getError().localizedDescription)")
        }
    }

    private func handleCredentialEvent(_ event: WalletCredentialEvent) {
        switch event.getCredentialEvent() {
        case .CREDENTIAL_UPDATED:
            self.handleCredentialUpdate(event.getAction(), referenceCredentialId: event.getReferenceCredentialId())
        }
    }
    
    private func handleCredentialUpdate(_ action: CredentialAction, referenceCredentialId: String) {
        switch action {
        case .DELETE:
            self.pingoneWalletClient.getDataRepository().deleteCredential(forId: referenceCredentialId)
        }
    }
    
}

// Mark: ApplicationUiCallbackHandler methods

extension PingOneWalletHelper {
    
    private func notifyUser(message: String) {
        logattention(message)
        self.applicationUiCallbackHandler?.showToast(message: message, hideAfter: Self.TOAST_DURATION)
    }
    
    private func askUserPermission(title: String, message: String, actionHandler: @escaping (Bool) -> Void, positiveActionTitle: String = "Confirm", cancelActionTitle: String = "Cancel") {
        guard let applicationUiCallbackHandler = self.applicationUiCallbackHandler else {
            actionHandler(true)
            return
        }
        
        applicationUiCallbackHandler.showConfirmationAlert(title: title, message: message, positiveActionTitle: positiveActionTitle, cancelActionTitle: cancelActionTitle, actionHandler: actionHandler)
    }
    
    private func showError(title: String, message: String) {
        logerror("\(title): \(message)")
        self.applicationUiCallbackHandler?.showErrorAlert(title: title, message: message, actionTitle: "Okay", actionHandler: nil)
    }
    
}
