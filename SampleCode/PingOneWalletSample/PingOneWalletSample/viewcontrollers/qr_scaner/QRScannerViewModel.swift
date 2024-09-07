//
//  QRScannerViewModel.swift
//  PingOneWalletSample
//
//

import Foundation

public class QRScannerViewModel: BaseViewModel {
    
    public var pingOneWalletHelper: PingOneWalletHelper
    
    required public init(pingOneWalletHelper: PingOneWalletHelper) {
        self.pingOneWalletHelper = pingOneWalletHelper
    }
    
    public func processQrCode(qrContent: String) {
        self.pingOneWalletHelper.processPingOneRequest(qrContent)
    }
    
}
