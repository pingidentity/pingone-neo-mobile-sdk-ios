//
//  EventObserverUtils.swift
//  PingOneWalletSample
//
//

import Foundation
import DIDSDK

public class EventObserverUtils {
    
    public static let PUSH_TOKEN_REGISTERED_KEY = "push_token_registered_key"
    public static let APP_OPEN_URL_NOTIFICATION_KEY = "app_open_url_notification_key"
    public static let CREDENTIALS_UPDATED_NOTIFICATION_KEY = "credentials_updated_notification_key"
    public static let REMOTE_NOTIFICATION_RECEIVED_KEY = "remote_notification_received_key"
    
    public static let PUSH_TOKEN_USERINFO_KEY = "push_token_userinfo_key"
    public static let APP_OPEN_URL_USERINFO_KEY = "app_open_url_userinfo_key"
    
    public class func broadcastPushTokenRegistrationNotification(_ pushToken: Data) {
        NotificationCenter.default.post(name: NSNotification.Name(EventObserverUtils.PUSH_TOKEN_REGISTERED_KEY), object: nil, userInfo: [PUSH_TOKEN_USERINFO_KEY: pushToken])
    }
    
    public class func broadcastAppOpenUrlNotification(_ appOpenUrl: String) {
        NotificationCenter.default.post(name: NSNotification.Name(EventObserverUtils.APP_OPEN_URL_NOTIFICATION_KEY), object: nil, userInfo: [APP_OPEN_URL_USERINFO_KEY: appOpenUrl])
    }
    
    
    public class func broadcastCredentialsUpdatedNotification(delayBy: TimeInterval?) {
        let delay = delayBy ?? 0
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: DispatchTime.now() + delay) {
            NotificationCenter.default.post(name: NSNotification.Name(EventObserverUtils.CREDENTIALS_UPDATED_NOTIFICATION_KEY), object: nil)
        }
    }
    
    public class func broadcastRemoteNotificationReceived(_ notificationUserInfo: [AnyHashable: Any]?) {
        NotificationCenter.default.post(name: NSNotification.Name(EventObserverUtils.REMOTE_NOTIFICATION_RECEIVED_KEY), object: nil, userInfo: notificationUserInfo)
    }

}
