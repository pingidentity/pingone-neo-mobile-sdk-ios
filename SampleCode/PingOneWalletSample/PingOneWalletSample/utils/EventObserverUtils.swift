//
//  EventObserverUtils.swift
//  PingOneWalletSample
//
//

import Foundation
import DIDSDK

class EventObserverUtils {
    
    public static let PROFILE_CREATED_NOTIFICATION_KEY = "profile_created_notification_key"
    public static let CLAIMS_UPDATED_NOTIFICATION_KEY = "claims_updated_notification_key"
    public static let REMOTE_NOTIFICATION_RECEIVED_KEY = "remote_notification_received_key"
    
    public class func broadcastClaimsUpdatedNotification() {
        NotificationCenter.default.post(name: NSNotification.Name(EventObserverUtils.CLAIMS_UPDATED_NOTIFICATION_KEY), object: nil)
    }
    
    public class func observeClaimUpdates(onUpdate: @escaping ([Claim]) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: NSNotification.Name(EventObserverUtils.CLAIMS_UPDATED_NOTIFICATION_KEY), object: nil, queue: nil) { _ in
            onUpdate(DataRepository.shared.getAllClaims())
        }
    }

    public class func broadcastProfileCreationNotification() {
        NotificationCenter.default.post(name: NSNotification.Name(EventObserverUtils.PROFILE_CREATED_NOTIFICATION_KEY), object: nil)
    }
    
    public class func observeProfileCreation(onUpdate: @escaping (Profile?) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: NSNotification.Name(EventObserverUtils.PROFILE_CREATED_NOTIFICATION_KEY), object: nil, queue: nil) { _ in
            onUpdate(DataRepository.shared.getProfile())
        }
    }
    
    public class func broadcastRemoteNotificationReceived(_ notificationUserInfo: [AnyHashable: Any]?) {
        NotificationCenter.default.post(name: NSNotification.Name(EventObserverUtils.REMOTE_NOTIFICATION_RECEIVED_KEY), object: nil, userInfo: notificationUserInfo)
    }
    
    public class func observeRemoteNotifications(onUpdate: @escaping ([AnyHashable: Any]?) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: NSNotification.Name(EventObserverUtils.REMOTE_NOTIFICATION_RECEIVED_KEY), object: nil, queue: nil) { onUpdate($0.userInfo)
        }
    }
    
    public class func removeObserver(_ observer: NSObjectProtocol?) {
        guard let observer = observer else {
            return
        }
        NotificationCenter.default.removeObserver(observer)
    }

}
