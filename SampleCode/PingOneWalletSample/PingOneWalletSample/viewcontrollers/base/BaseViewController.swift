//
//  BaseViewController.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit

public protocol BaseViewController: UIViewController {
    
    var walletCoordinator: WalletCoordinator! {get set}
    
    static func instantiate() -> Self
    func setViewModel<VM: BaseViewModel>(_ viewModel: VM)

}

public extension BaseViewController {
    
    static func instantiate() -> Self {
        let storyboardIdentifier = String(describing: Self.self)
        let storyboard = UIStoryboard(name: AppDelegate.STORYBOARD_NAME, bundle: Bundle.main)
        return storyboard.instantiateViewController(withIdentifier: storyboardIdentifier) as! Self
    }
    
    func setNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "nav_bar_color") ?? UIColor(netHex: 0x2996CC)
        
        let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.buttonAppearance = buttonAppearance
        
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = self.navigationController?.navigationBar.standardAppearance
    }
}
