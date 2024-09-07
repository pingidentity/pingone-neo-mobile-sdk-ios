//
//  CredentialDetailsViewModel.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import DIDSDK
import PingOneWallet

public class CredentialDetailsViewModel: BaseViewModel {
    
    public var pingOneWalletHelper: PingOneWalletHelper
 
    private var credential: Claim!
    private var sortedClaims: [(String, String)] = []
    private var actionType: CredentialDetailsViewAction = .DELETE
    
    public required init(pingOneWalletHelper: PingOneWalletHelper) {
        self.pingOneWalletHelper = pingOneWalletHelper
    }

    func setCredential(_ credential: Claim) {
        self.credential = credential
        self.sortedClaims = credential.getData()
            .filter({ $0.key != ClaimKeys.cardImage })
            .map({ ($0.key, $0.value) })
            .sorted { $0.0 < $1.0 }
    }
    
    func setCredentialAction(_ credentialAction: CredentialDetailsViewAction) {
        self.actionType = credentialAction
    }
    
    func getCredentialAction() -> CredentialDetailsViewAction {
        return self.actionType
    }
    
    func getSortedClaims() -> [(String, String)] {
        return self.sortedClaims
    }
    
    func getClaimFor(index: Int) -> (String, String) {
        return self.sortedClaims[index]
    }
    
    func getCredentialImage(forSize size: CGSize) -> UIImage? {
        return UIImage.fromClaim(self.credential, size: size)
    }
    
    func getCredential() -> Claim {
        return self.credential
    }
    
    func isRevoked() -> Bool {
        return self.pingOneWalletHelper.getDataRepository().isCredentialRevoked(credentialId: self.credential.getId())
    }
    
    func getIssuerMetadata() -> CompletionHandler<IssuerMetadata> {
        return CredentialUtils.getCredentialIssuerMetadataFromClaim(self.credential)
    }
    
    func performAction() {
        switch self.actionType {
        case .ACCEPT:
            self.pingOneWalletHelper.getDataRepository().saveCredential(self.credential)
            return
        case .DELETE:
            self.pingOneWalletHelper.getDataRepository().deleteCredential(forId: self.credential.getId())
            self.pingOneWalletHelper.reportCredentialDeletion(self.credential)
            EventObserverUtils.broadcastCredentialsUpdatedNotification(delayBy: 1)
            return
        }
    }
}
