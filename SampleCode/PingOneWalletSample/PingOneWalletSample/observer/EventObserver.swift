//
//  EventObserver.swift
//  PingOneWalletSample
//
//

import Foundation
import DIDSDK

public class EventObserver {
    
    var networkReachabilityObserver: NSObjectProtocol?
    var pushTokenRegistrationObserver: NSObjectProtocol?
    var appOpenUrlObserver: NSObjectProtocol?
    var credentialUpdatesObserver: NSObjectProtocol?
    var remoteNotificationObserver: NSObjectProtocol?
    
    public func observeNetworkReachability(onUpdate: @escaping (NetworkReachability.NetworkReachabilityStatus) -> Void) {
        self.networkReachabilityObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(NetworkReachability.NETWORK_REACHABILITY_UPDATED), object: nil, queue: nil) { (notification) in
            guard let networkStatus = notification.userInfo?[NetworkReachability.NETWORK_REACHABILITY_STATUS] as? NetworkReachability.NetworkReachabilityStatus else {
                return
            }
            onUpdate(networkStatus)
        }
    }
    
    public func observePushTokenRegistration(onUpdate: @escaping (Data) -> Void) {
        self.pushTokenRegistrationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(EventObserverUtils.PUSH_TOKEN_REGISTERED_KEY), object: nil, queue: nil, using: { notification in
            guard let pushToken = notification.userInfo?[EventObserverUtils.PUSH_TOKEN_USERINFO_KEY] as? Data else {
                return
            }
            onUpdate(pushToken)
        })
    }
    
    public func observeAppOpenUrl(onUpdate: @escaping (String) -> Void) {
        self.appOpenUrlObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(EventObserverUtils.APP_OPEN_URL_NOTIFICATION_KEY), object: nil, queue: nil, using: { notification in
            guard let appOpenUrl = notification.userInfo?[EventObserverUtils.APP_OPEN_URL_USERINFO_KEY] as? String else {
                return
            }
            onUpdate(appOpenUrl)
        })
    }
    
    public func observeCredentialUpdates(onUpdate: @escaping () -> Void) {
        self.credentialUpdatesObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(EventObserverUtils.CREDENTIALS_UPDATED_NOTIFICATION_KEY), object: nil, queue: nil) { _ in
            onUpdate()
        }
    }

    public func observeRemoteNotifications(onUpdate: @escaping ([AnyHashable: Any]?) -> Void) {
        self.remoteNotificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(EventObserverUtils.REMOTE_NOTIFICATION_RECEIVED_KEY), object: nil, queue: nil) { onUpdate($0.userInfo)
        }
    }
    
    public func removeObservers() {
        Self.removeObserver(self.networkReachabilityObserver)
        Self.removeObserver(self.pushTokenRegistrationObserver)
        Self.removeObserver(self.credentialUpdatesObserver)
        Self.removeObserver(self.remoteNotificationObserver)
    }
    
    class func removeObserver(_ observer: NSObjectProtocol?) {
        guard let observer = observer else {
            return
        }
        NotificationCenter.default.removeObserver(observer)
    }
    
}
