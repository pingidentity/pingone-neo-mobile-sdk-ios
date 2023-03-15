//
//  ItemPickerTableViewCell.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import PingOneWallet
import DIDSDK

class ItemPickerTableViewCell: UITableViewCell {
    
    static let CELL_REUSE_IDENTIFIER: String = "ItemPickerTableViewCell"

    static var nib: UINib {
        return UINib(nibName: "ItemPickerTableViewCell", bundle: nil)
    }
    
    @IBOutlet weak var cardTitle: UILabel!
    @IBOutlet weak var cardImage: UIImageView!
    @IBOutlet weak var revokedLabel: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.contentView.frame = contentView.frame.insetBy(dx: 0, dy: 10)
    }
    
    public func populate(pickerItem: PickerItem) {
        self.contentView.layer.cornerRadius = 10
        self.contentView.layer.borderColor = UIColor.lightGray.cgColor
        self.contentView.layer.borderWidth = 1.0
        self.contentView.backgroundColor = UIColor(named: "card_bg_color") ?? UIColor(netHex: 0xB1BCBE)
        
        self.cardImage.contentMode = .scaleAspectFit
        self.cardImage.image = pickerItem.image
        self.cardTitle.text = pickerItem.label
        self.revokedLabel.isHidden = !pickerItem.showStaticLabel
        
        self.layoutIfNeeded()
    }
}
    

