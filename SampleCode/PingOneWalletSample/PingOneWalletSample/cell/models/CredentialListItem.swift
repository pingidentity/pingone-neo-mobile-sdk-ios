//
//  CredentialListItem.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit

public struct CredentialListItem {
    
    let cardTitle: String?
    let cardImage: UIImage?
    let isRevoked: Bool
    
    init(cardTitle: String?, cardImage: UIImage?, isRevoked: Bool) {
        self.cardTitle = cardTitle
        self.cardImage = cardImage
        self.isRevoked = isRevoked
    }
    
}
