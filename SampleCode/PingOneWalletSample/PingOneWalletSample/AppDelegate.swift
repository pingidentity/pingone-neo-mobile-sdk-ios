//
//  AppDelegate.swift
//  PingOneWalletSample
//
//

import UIKit
import DIDSDK
import PingOneWallet

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    public static let STORYBOARD_NAME = "Main"
    
    var window: UIWindow?
    
    var pnToken: Data? {
        didSet {
            guard let token = pnToken else {
                return
            }
            EventObserverUtils.broadcastPushTokenRegistrationNotification(token)
        }
    }
    
    var notificationUserInfo: [AnyHashable: Any]? {
        didSet {
            EventObserverUtils.broadcastRemoteNotificationReceived(self.notificationUserInfo)
        }
    }
    
    var appOpenUrl: String? {
        didSet {
            guard let appOpenUrl = self.appOpenUrl else {
                logerror("Empty AppOepn URL, nothing to handle")
                return
            }
            
            EventObserverUtils.broadcastAppOpenUrlNotification(appOpenUrl)
        }
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.window = self.window ?? UIWindow()
        
        let waitOverlay = WaitOverlayView.instantiate()
        waitOverlay.setMessage("Initializing application...")
        let navigationController = UINavigationController(rootViewController: waitOverlay)
        navigationController.navigationBar.isHidden = true
        self.window!.rootViewController = navigationController
        self.window!.makeKeyAndVisible()

        PingOneWalletHelper.initializeWallet()
            .onError { error in
                logerror("Error initializing SDK: \(error.localizedDescription)")
                ApplicationUiHandler().showErrorAlert(title: "Error", message: "Error initializing Wallet, app may behave unexpectedly.", actionTitle: "Okay", actionHandler: nil)
            }
            .onResult { pingOneWalletHelper in
                let coordinator = WalletCoordinator(navigationController: navigationController, pingOneWalletHelper: pingOneWalletHelper)
                pingOneWalletHelper.setApplicationUiCallbackHandler(coordinator)
                pingOneWalletHelper.setCredentialPicker(DefaultCredentialPicker(applicationUiCallbackHandler: coordinator))
                coordinator.showHomeView()
                pingOneWalletHelper.processLaunchOptions(launchOptions)
            }
        
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        logattention("didRegisterForRemoteNotificationsWithDeviceToken: \(deviceToken.hexDescription)")
        self.pnToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logerror("Error: App was unable to register for remote notifications: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        UIApplication.shared.applicationIconBadgeNumber = 0  // clear notification badge if it's there
        logattention("Notification Received")
        self.notificationUserInfo = userInfo
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Get URL components from the incoming user activity.
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let appOpenUrl = userActivity.webpageURL, UIApplication.shared.canOpenURL(appOpenUrl) else {
            return false
        }
        logattention("AppOpenUrl: \(appOpenUrl)")
        self.appOpenUrl = appOpenUrl.absoluteString
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let callingApp = options[.sourceApplication]
        logattention("URL Received from application: \(callingApp ?? "Unknown")")
        
        guard (UIApplication.shared.canOpenURL(url)) else {
            return false
        }
        
        if let scheme = url.scheme,
            scheme.starts(with: "openid"),
            !self.isValidOpenIdVcUrl(url) {
            return false
        }
        logattention("App opened using url: \(url)")
        self.appOpenUrl = url.absoluteString
        
        return true
    }
    
    private func isValidOpenIdVcUrl(_ url: URL) -> Bool {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false),
              let params = components.queryItems else {
            return false
        }
        
        guard params.filter({$0.name == "request_uri"}).first != nil else {
            return false
        }
        //Can perform further checks here if needed
        return true
    }
    
    public func registerForAPNS() {
        DispatchQueue.main.async {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    logerror("Error: User denied permission for push notifications. \(error.localizedDescription)")
                    return
                }
                
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
        }
    }
    
}

extension AppDelegate: StorageErrorHandler {
    
    func handleStorageError(_ error: StorageError) {
        logerror(error.localizedDescription)
    }
    
}
