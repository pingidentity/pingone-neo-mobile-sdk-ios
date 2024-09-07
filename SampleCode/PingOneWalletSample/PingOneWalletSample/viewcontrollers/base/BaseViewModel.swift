//
//  BaseViewModel.swift
//  PingOneWalletSample
//
//

import Foundation
import DIDSDK
import PingOneWallet

public protocol BaseViewModel: AnyObject {
    
    var pingOneWalletHelper: PingOneWalletHelper {get set}

    init(pingOneWalletHelper: PingOneWalletHelper)
    
    func getPingOneWalletHelper() -> PingOneWalletHelper
        
}

public extension BaseViewModel {

    func getPingOneWalletHelper() -> PingOneWalletHelper {
        return self.pingOneWalletHelper
    }

}
