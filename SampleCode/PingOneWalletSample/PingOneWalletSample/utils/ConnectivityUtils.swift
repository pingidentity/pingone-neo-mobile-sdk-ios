//
//  ConnectivityUtils.swift
//  PingOneWalletSample
//
//

import Foundation
import PingOneWallet
import DIDSDK

public class ConnectivityUtils {
    
    class func checkNetworkStatus() -> Bool {
        if let networkReachability = NetworkReachability() {
            logattention("Starting network status notifier: \(networkReachability.startNotifier())")
            switch networkReachability.currentNetworkStatus {
            case .available(_):
                logattention("Network status check successful - Available.")
                return true
            case .unavailable,
                 .unknown:
                return false
            }
        } else {
            logerror("Failed to initialize NetworkReachability.")
            return false
        }
    }
    
}
