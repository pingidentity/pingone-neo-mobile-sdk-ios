//
//  HomeViewModel.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import DIDSDK
import PingOneWallet

public class HomeViewModel: BaseViewModel {
    
    public var pingOneWalletHelper: PingOneWalletHelper
    
    private var eventObserver: EventObserver!
    private var credentials: [Claim] = []
    
    required public init(pingOneWalletHelper: PingOneWalletHelper) {
        self.pingOneWalletHelper = pingOneWalletHelper
    }
    
    func observeCredentialUpdates(onUpdate: @escaping () -> Void) {
        self.getEventObserver().observeCredentialUpdates {
            self.getAllCredentials()
            onUpdate()
        }
    }
        
    func checkForMessages() {
        self.pingOneWalletHelper.checkForMessages()
    }
    
    func getCredentialFor(index: Int) -> Claim {
        return self.credentials[index]
    }
    
    func getListItemFor(index: Int, size: CGSize) -> CredentialListItem {
        let credential = self.getCredentialFor(index: index)
        return CredentialListItem(cardTitle: credential.getData()[ClaimKeys.cardType], cardImage: UIImage.fromClaim(credential, size: size), isRevoked: self.isCredentialRevoked(credential))
    }
    
    func isCredentialRevoked(_ credential: Claim) -> Bool {
        return self.pingOneWalletHelper.getDataRepository().isCredentialRevoked(credentialId: credential.getId())
    }
    
    @discardableResult
    func getAllCredentials() -> [Claim] {
        self.credentials = self.pingOneWalletHelper.getDataRepository().getAllCredentials()
        return self.credentials
    }
    
    func isPollingEnabled() -> Bool {
        return self.pingOneWalletHelper.isPollingEnabled()
    }
    
    func pollForMessages() {
        self.pingOneWalletHelper.pollForMessages()
    }
    
    func stopPolling() {
        self.pingOneWalletHelper.stopPolling()
    }
    
    private func getEventObserver() -> EventObserver {
        if self.eventObserver == nil {
            self.eventObserver = EventObserver()
        }
        return self.eventObserver
    }

}
