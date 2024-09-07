//
//  BaseCoordinator.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import DIDSDK
import PingOneWallet

public class WalletCoordinator {
    
    static let TOAST_DURATION: TimeInterval = 2.0
    
    var navigationController: UINavigationController
    var pingOneWalletHelper: PingOneWalletHelper
    var applicationUiHandler: ApplicationUiHandler! = ApplicationUiHandler()
    
    var eventObserver: EventObserver
    
    var waitOverlayViewController: WaitOverlayView?
    
    init(navigationController: UINavigationController, pingOneWalletHelper: PingOneWalletHelper) {
        self.navigationController = navigationController
        self.eventObserver = EventObserver()
        self.pingOneWalletHelper = pingOneWalletHelper
        
        self.registerObservers()
    }
    
    private func checkConnectivity() -> Bool {
        return ConnectivityUtils.checkNetworkStatus()
    }
    
    private func registerObservers() {
        self.eventObserver.observeNetworkReachability { status in
            if (status == .unavailable) {
                self.showErrorAlert(title: "Not connected", message: "Make sure you're connected to internet and restart the app.", actionTitle: "Ok") {
                    self.showToast(message: "Network not available")
                }
            }
        }
        self.eventObserver.observeRemoteNotifications { userInfo in
            self.pingOneWalletHelper.processPingOneNotification(userInfo)
        }
        
        self.eventObserver.observePushTokenRegistration { pushToken in
            self.pingOneWalletHelper.updatePushToken(pushToken)
        }
        
        self.eventObserver.observeAppOpenUrl { appOpenUrl in
            self.pingOneWalletHelper.processPingOneRequest(appOpenUrl)
        }
    }
    
    deinit {
        self.eventObserver.removeObservers()
    }
    
    public func showWaitOverlay(_ message: String) {
        DispatchQueue.main.async {
            self.waitOverlayViewController = WaitOverlayView.instantiate()
            self.waitOverlayViewController!.setMessage(message)
            self.waitOverlayViewController!.modalPresentationStyle = .fullScreen
            self.navigationController.present(self.waitOverlayViewController!, animated: false)
        }
    }
    
    public func hideWaitOverlay(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.waitOverlayViewController?.dismiss(animated: false, completion: completion)
        }
    }
    
    public func showHomeView() {
        DispatchQueue.main.async {
            let homeView = HomeView(coordinator: self, pingOneWalletHelper: self.pingOneWalletHelper)
            self.navigationController.navigationBar.isHidden = false
            self.navigationController.setViewControllers([homeView.getViewController()], animated: false)
        }
    }
    
    public func pushCredentialDetails(_ credential: Claim) {
        DispatchQueue.main.async {
            let credentialDetailsView = CredentialDetailsView(coordinator: self, pingOneWalletHelper: self.pingOneWalletHelper)
            credentialDetailsView.viewModel.setCredential(credential)
            credentialDetailsView.viewModel.setCredentialAction(.DELETE)
            self.navigationController.pushViewController(credentialDetailsView.getViewController(), animated: true)
        }
    }
    
    public func showQrScanner() {
        #if targetEnvironment(simulator) //Strictly for local testing
        let alertController = UIAlertController(title: "Copy the URL for execution", message: "", preferredStyle: .alert)
        alertController.addTextField()
        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            guard let text = alertController.textFields?.first?.text else {
                return
            }
            logattention("Processing URL - \(text)")
            self.pingOneWalletHelper.processPingOneRequest(text)
        }
        alertController.addAction(submitAction)
        self.navigationController.present(alertController, animated: true)
        #else
        DispatchQueue.main.async {
            let qrScannerView = QRScannerView(coordinator: self, pingOneWalletHelper: self.pingOneWalletHelper)
            let qrScannerViewController = qrScannerView.getViewController()
            //        qrScannerViewController.modalPresentationStyle = .currentContext
            self.navigationController.present(qrScannerViewController, animated: true)
        }
        #endif
    }
    
    public func showPicker(_ items: [PickerItem], pickerListener: PickerListener) {
        DispatchQueue.main.async {
            let pickerView = PickerView(coordinator: self, pingOneWalletHelper: self.pingOneWalletHelper)
            pickerView.viewModel.setPickerItems(items)
            pickerView.viewModel.setPickerListener(pickerListener)
            self.navigationController.present(pickerView.getViewController(), animated: true)
        }
    }
    
}

extension WalletCoordinator: ApplicationUiCallbackHandler {
    
    public func showConfirmationAlert(title: String, message: String, positiveActionTitle: String, cancelActionTitle: String, actionHandler: @escaping (Bool) -> Void) {
        self.applicationUiHandler.showConfirmationAlert(title: title, message: message, positiveActionTitle: positiveActionTitle, cancelActionTitle: cancelActionTitle, actionHandler: actionHandler)
    }
    
    public func showErrorAlert(title: String, message: String, actionTitle: String?, actionHandler: (() -> Void)?) {
        self.applicationUiHandler.showErrorAlert(title: title, message: message, actionTitle: actionTitle, actionHandler: actionHandler)
    }
    
    public func selectCredentialForPresentation(_ credentials: [Claim], onItemPicked: @escaping ((Claim?) -> Void)) {
        let claims = credentials.filter { $0.getData()[ClaimKeys.cardType] != nil }
        let pickerItems = credentials.compactMap { DefaultCredentialPicker.getPickerItemFromClaims($0, isRevoked: self.pingOneWalletHelper.getDataRepository().isCredentialRevoked(credentialId: $0.getId())) }
        
        self.showPicker(pickerItems, pickerListener: ItemPickerListener(claims: claims, onItemPicked: onItemPicked))
    }
    
    public func showToast(message: String, hideAfter duration: TimeInterval) {
        self.applicationUiHandler.showToast(message: message, hideAfter: duration)
    }
    
    public func showToast(message: String) {
        self.applicationUiHandler.showToast(message: message)
    }
    
    public func hideToast() {
        self.applicationUiHandler.hideToast()
    }
    
    public func openUrl(url: String, onComplete: @escaping (Bool, String) -> Void) {
        self.applicationUiHandler.openUrl(url: url, onComplete: onComplete)
    }
}

class ItemPickerListener: PickerListener {
    
    let claims: [Claim]
    let onEvent: (Claim?) -> Void
    
    init(claims: [Claim], onItemPicked: @escaping (Claim?) -> Void) {
        self.claims = claims
        self.onEvent = onItemPicked
    }
    
    func onItemPicked(index: Int) {
        guard index < self.claims.count else {
            logerror("Something is wrong...")
            self.onEvent(nil)
            return
        }
        
        self.onEvent(self.claims[index])
    }
    
    func onPickerCanceled() {
        self.onEvent(nil)
    }
    
}
