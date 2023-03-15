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
    
    var window: UIWindow?
    
    var pnToken: Data? {
        didSet {
            guard let token = pnToken?.hexDescription,
                  let _ = DataRepository.shared else{
                return
            }
            PingOneWalletHelper.shared.updatePushToken(token)
        }
    }
    
    var notificationUserInfo: [AnyHashable: Any]? {
        didSet {
            EventObserverUtils.broadcastRemoteNotificationReceived(self.notificationUserInfo)
        }
    }
    
    var appOpenUrl: String? {
        didSet {
            guard (DataRepository.shared != nil) else {
                logattention("App not initialized")
                return
            }
            
            guard let _ = DataRepository.shared.getProfile() else {
                NotificationUtils.showToast(message: "Must create profile before pairing")
                return
            }
            
            guard let appOpenUrl = self.appOpenUrl else {
                logerror("Empty AppOepn URL, nothing to handle")
                return
            }
            
            PingOneWalletHelper.shared.processQrContent(appOpenUrl)
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        AppDelegate.checkNetworkStatus()
        NotificationCenter.default.addObserver(forName: NSNotification.Name(NetworkReachability.NETWORK_REACHABILITY_UPDATED), object: nil, queue: nil) { (notification) in
            guard let networkStatus = notification.userInfo?[NetworkReachability.NETWORK_REACHABILITY_STATUS] as? NetworkReachability.NetworkReachabilityStatus else {
                return
            }
            
            if (networkStatus == .unavailable || networkStatus == .unknown) {
                NotificationUtils.showToast(message: "Network not available.", isPermanent: true)
            } else {
                NotificationUtils.hideToast()
            }
        }
        
        
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        logattention("didRegisterForRemoteNotificationsWithDeviceToken: \(deviceToken.hexDescription)")
        self.pnToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logerror("Error: App was unable to register for remote notifications: \(error.localizedDescription)")
        NotificationUtils.showToast(message: "Failed to register for notifications")
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
    
    public class func registerForAPNS() {
        DispatchQueue.main.async {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    logerror("Error: User denied permission for push notifications. \(error.localizedDescription)")
                    return
                }
                
                if (!granted) {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
            
        }
    }
    
    class func checkNetworkStatus() {
        if let networkReachability = NetworkReachability() {
            logattention("Starting network status notifier: \(networkReachability.startNotifier())")
            switch networkReachability.currentNetworkStatus {
            case .available(_):
                logattention("Network status check successful - Available.")
            case .unavailable,
                 .unknown:
                NotificationUtils.showToast(message: "Network not available.", isPermanent: true)
            }
        } else {
            logerror("Failed to initialize NetworkReachability.")
        }
    }
    
}

extension AppDelegate: StorageErrorHandler {
    
    func handleStorageError(_ error: StorageError) {
        logerror(error.localizedDescription)
    }
    
}
