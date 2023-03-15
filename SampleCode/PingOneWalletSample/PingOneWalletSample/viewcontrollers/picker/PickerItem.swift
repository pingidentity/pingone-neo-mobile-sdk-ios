//
//  PickerItem.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import DIDSDK
import PingOneWallet

struct PickerItem {
    
    var id: String!
    var image: UIImage?
    var label: String!
    var secondaryLabel: String?
    var showStaticLabel: Bool = false
    
    init(id: String, image: UIImage?, label: String, secondaryLabel: String?, showStaticLabel: Bool) {
        self.id = id
        self.image = image
        self.label = label
        self.secondaryLabel = secondaryLabel
        self.showStaticLabel = showStaticLabel
    }
    
    init?(from claim: Claim, isRevoked: Bool) {
        guard let type = claim.getData()[ClaimKeys.cardType] else {
            return nil
        }
        self.init(id: claim.getId(), image: UIImage.fromClaim(claim, size: nil), label: type, secondaryLabel: DateUtils.getIssueDate(from: claim), showStaticLabel: isRevoked)
    }

}
