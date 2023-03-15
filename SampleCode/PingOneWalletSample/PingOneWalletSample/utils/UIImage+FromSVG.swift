//
//  UIImage+FromSVG.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import PingOneWallet
import DIDSDK
import SVGKit

extension UIImage {
    
    static func fromClaim(_ claim: Claim, size: CGSize?) -> UIImage? {
        if let cardImageStr = claim.getData()[ClaimKeys.cardImage] {
           return fromSvg(cardImageStr, size: size)
        }
        logerror("Failed to parse svg image")
        return nil
    }
    
    static func fromSvg(_ svg: String, size: CGSize?) -> UIImage? {
        if let svgImage = SVGKImage(data: svg.toData()) {
            if let size = size {
                svgImage.scaleToFit(inside: size)
            }
            return svgImage.uiImage
        }
        return nil
    }
    
}
