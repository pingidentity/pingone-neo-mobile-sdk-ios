//
//  IssuerDetailsView.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import PingOneWallet

public class IssuerDetailsView: UIView {
    
    @IBOutlet weak var issuerLogoView: UIImageView!
    @IBOutlet weak var issuerNameLabel: UILabel!
    @IBOutlet weak var issuerLabel: UILabel!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    private func setupView() {
        let bundle = Bundle(for: type(of: self))
        if let nib = bundle.loadNibNamed("IssuerDetailsView", owner: self) {
            if let subview = nib[0] as? UIView {
                subview.frame = self.bounds
                subview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.addSubview(subview)
            }
        }
    }
    
    public func populate(_ issuerMetadata: IssuerMetadata) {
        if let issuerLogoUrl = issuerMetadata.getLogo() {
            self.issuerLogoView.loadFrom(issuerLogoUrl, defaultImage: UIImage(named: "default_logo"))
        } else {
            self.issuerLogoView.image = UIImage(named: "default_logo")
        }
        
        issuerLabel.text = issuerMetadata.getCredentialIssuer()
        issuerNameLabel.text = issuerMetadata.getName()
    }
    
}
