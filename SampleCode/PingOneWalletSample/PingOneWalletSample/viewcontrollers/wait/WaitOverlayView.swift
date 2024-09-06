//
//  WaitOverlayView.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit

public class WaitOverlayView: UIViewController {
    
    @IBOutlet weak var messageLabel: UILabel!
    
    private var messageString: String! = "Please wait..." {
        didSet {
            self.messageLabel?.text = self.messageString
        }
    }
    
    public static func instantiate() -> Self {
        let storyboardIdentifier = String(describing: Self.self)
        let storyboard = UIStoryboard(name: AppDelegate.STORYBOARD_NAME, bundle: Bundle.main)
        return storyboard.instantiateViewController(withIdentifier: storyboardIdentifier) as! Self
    }
    
    public func setMessage(_ message: String) {
        self.messageString = message
    }
    
}
