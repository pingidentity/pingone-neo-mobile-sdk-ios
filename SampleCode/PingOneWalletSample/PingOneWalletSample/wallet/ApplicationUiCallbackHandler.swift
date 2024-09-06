//
//  ApplicationUiCallbacks.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import DIDSDK

public protocol ApplicationUiCallbackHandler {
    
    func showConfirmationAlert(title: String, message: String, positiveActionTitle: String, cancelActionTitle: String, actionHandler: @escaping (Bool) -> Void)
    func showErrorAlert(title: String, message: String, actionTitle: String?, actionHandler: (() -> Void)?)
    func selectCredentialForPresentation(_ credentials: [Claim], onItemPicked: @escaping ((Claim?) -> Void))
    func showToast(message: String, hideAfter duration: TimeInterval)
    func showToast(message: String)
    func hideToast()
    func openUrl(url: String, onComplete: @escaping (Bool, String) -> Void)
    
}
