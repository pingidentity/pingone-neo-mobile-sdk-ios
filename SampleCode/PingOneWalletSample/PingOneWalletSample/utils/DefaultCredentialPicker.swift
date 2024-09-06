//
//  ClaimPickerView.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import DIDSDK
import PingOneWallet

public class DefaultCredentialPicker: CredentialPicker {
    
    public let applicationUiCallbackHandler: ApplicationUiCallbackHandler
    
    init(applicationUiCallbackHandler: ApplicationUiCallbackHandler) {
        self.applicationUiCallbackHandler = applicationUiCallbackHandler
    }
    
    public func selectCredentialFor(presentationRequest: PresentationRequest, credentialMatcherResults: [CredentialMatcherResult], onResult: @escaping (_ result: CredentialsPresentation?) -> Void) {
        let listener = DefaultCredentialPickerListener(for: presentationRequest, onEvent: onResult)
        self.selectCredentialToPresent(credentialMatcherResults, index: 0, listener: listener)
    }
    
    private func selectCredentialToPresent(_ credentialMatcherResults: [CredentialMatcherResult], index: Int, listener: CredentialPickerListener) {
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
            listener.onCredentialPicked(credentialMatcherResult.claims[0], keys: credentialMatcherResult.requestedKeys)
            self.selectCredentialToPresent(credentialMatcherResults, index: index + 1, listener: listener)
        } else {
            //MARK: UI Code
            self.applicationUiCallbackHandler.selectCredentialForPresentation(credentialMatcherResult.claims) { selectedClaim in
                guard let claim = selectedClaim else {
                    listener.onPickerCanceled()
                    return
                }
                listener.onCredentialPicked(claim, keys: credentialMatcherResult.requestedKeys)
                self.selectCredentialToPresent(credentialMatcherResults, index: index + 1, listener: listener)
            }
        }
    }
    
    class func getPickerItemFromClaims(_ claim: Claim, isRevoked: Bool) -> PickerItem? {
        guard let type = claim.getData()[ClaimKeys.cardType] else {
            return nil
        }
        return PickerItem(id: claim.getId(), image: UIImage.fromClaim(claim, size: nil), label: type, secondaryLabel: DateUtils.getIssueDate(from: claim), showStaticLabel: isRevoked)
    }
    
}

class DefaultCredentialPickerListener: CredentialPickerListener {
    
    var result: CredentialsPresentation
    var onEvent: ((CredentialsPresentation?) -> Void)
    
    init(for presentationRequest: PresentationRequest, onEvent: @escaping (CredentialsPresentation?) -> Void) {
        self.result = CredentialsPresentation(presentationRequest: presentationRequest)
        self.onEvent = onEvent
    }
    
    func onCredentialPicked(_ claim: Claim, keys: [String]) {
        self.result.addClaimForKeys(claim, keys: keys)
    }
    
    func onPickerComplete() {
        self.onEvent(self.result)
    }
    
    func onPickerCanceled() {
        self.onEvent(nil)
    }
    
}
