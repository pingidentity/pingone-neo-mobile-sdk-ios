//
//  PickerItem.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit

public struct PickerItem {
    
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

}
