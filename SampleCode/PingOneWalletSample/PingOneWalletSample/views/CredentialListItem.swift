//
//  CredentialListItem.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import DIDSDK
import PingOneWallet

class CredentialListItem: UITableViewCell {
    
    static let CELL_REUSE_IDENTIFIER: String = "CredentialListItemCell"

    static var nib: UINib {
        return UINib(nibName: "CredentialListItem", bundle: nil)
    }
    
    @IBOutlet weak var cardTitle: UILabel!
    @IBOutlet weak var cardImage: UIImageView!
    @IBOutlet weak var revokedLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.contentView.frame = contentView.frame.insetBy(dx: 0, dy: 10)
    }
    
    public func populate(credential: Claim, isRevoked: Bool) {
        self.contentView.layer.cornerRadius = 10
        self.contentView.layer.borderColor = UIColor.lightGray.cgColor
        self.contentView.layer.borderWidth = 1.0
        self.contentView.backgroundColor = UIColor(named: "card_bg_color") ?? UIColor(netHex: 0xB1BCBE)
        
        self.cardTitle.text = credential.getData()[ClaimKeys.cardType]
        self.cardImage.contentMode = .scaleAspectFit
        self.cardImage.image = UIImage.fromClaim(credential, size: self.cardImage.bounds.size)
        self.revokedLabel.isHidden = !isRevoked
        self.layoutIfNeeded()
    }
}
