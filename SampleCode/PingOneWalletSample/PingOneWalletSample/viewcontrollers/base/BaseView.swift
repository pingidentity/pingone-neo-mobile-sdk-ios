//
//  BaseView.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import PingOneWallet

public class BaseView<VM: BaseViewModel, VC: BaseViewController> {
    
    var coordinator: WalletCoordinator
    var viewController: VC
    var viewModel: VM
        
    public init(coordinator: WalletCoordinator, pingOneWalletHelper: PingOneWalletHelper) {
        self.coordinator = coordinator
        self.viewModel = VM.init(pingOneWalletHelper: pingOneWalletHelper)
        self.viewController = VC.instantiate()
        self.viewController.walletCoordinator = coordinator
        self.viewController.setViewModel(self.viewModel)
    }
    
    public func getViewModel() -> VM {
        return self.viewModel
    }
    
    public func getViewController() -> VC {
        return self.viewController
    }
    
}
