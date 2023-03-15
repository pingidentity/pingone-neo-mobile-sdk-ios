//
//  AlertUtils.swift
//  PingOneWalletSample
//
//

import Foundation
import PingOneWallet
import DIDSDK
import UIKit

class NotificationUtils {
    
    public static func showConfirmationAlert(title: String, message: String, actionHandler: @escaping (Bool, UIAlertController) -> Void, positiveActionTitle: String = "Confirm", cancelActionTitle: String = "Cancel") {
        DispatchQueue.main.async {
            let alertVc = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: positiveActionTitle, style: .default, handler: { _ in
                actionHandler(true, alertVc)
            }))
            alertVc.addAction(UIAlertAction(title: cancelActionTitle, style: .cancel, handler: { _ in
                actionHandler(false, alertVc)
            }))
            UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController?.present(alertVc, animated: true)
        }
    }
    
    public static func showClaimsPicker(_ claims: [Claim], onItemPicked: @escaping ((Claim?) -> Void)) {
        showPicker(claims.compactMap { PickerItem(from: $0, isRevoked: DataRepository.shared.isClaimRevoked(claimId: $0.getId())) }) { selectedIndex, itemPickerViewController in
            guard let index = selectedIndex else {
                onItemPicked(nil)
                return
            }
            
            let credential = claims[index]
            guard let detailsVc = CredentialDetailsViewController.initializeFor(credential: credential, actionLabel: "Confirm", action: { claim, detailsViewController in
                guard let claim = claim else {
                    return
                }
                itemPickerViewController?.navigationController?.popViewController(animated: true)
                onItemPicked(claim)
            }) else {
                logerror("Failed to initialize credential details view controller.")
                return
            }
            pushViewController(detailsVc)
        }
    }
    
    public static func showPicker(_ items: [PickerItem], onItemPicked: @escaping ((Int?, ItemPickerViewController?) -> Void)) {
        DispatchQueue.main.async {
            guard let credentialPickerVc = ItemPickerViewController.getItemPicker(headerTitle: nil, tableViewContent: items, onItemSelected: onItemPicked) else {
                logerror("Failed to initialize item picker view controller.")
                return
            }
            
            pushViewController(credentialPickerVc)
        }
    }
    
    public static func pushViewController(_ viewController: UIViewController) {
        let topViewController = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
        if let topNavController = topViewController as? UINavigationController {
            topNavController.pushViewController(viewController, animated: true)
        } else {
            topViewController?.present(viewController, animated: true)
        }
    }
    
    public static func showErrorAlert(title: String, message: String) {
        showErrorAlert(title: title, message: message, action: UIAlertAction(title: "Okay", style: .default))
    }
    
    public static func showErrorAlert(title: String, message: String, action: UIAlertAction) {
        DispatchQueue.main.async {
            let alertVc = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertVc.addAction(action)
            UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController?.present(alertVc, animated: true)
        }
    }
    
    public static func showToast(message: String, duration: TimeInterval = 3.0, isPermanent: Bool = false) {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
                return
            }
            
            self.hideToast()
            
            let toastContainer = UIView(frame: CGRect())
            toastContainer.tag = 1234
            toastContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            toastContainer.alpha = 0.0
            toastContainer.layer.cornerRadius = 25
            toastContainer.clipsToBounds  =  true
            
            let toastLabel = UILabel(frame: CGRect())
            toastLabel.textColor = UIColor.white.withAlphaComponent(0.8)
            toastLabel.textAlignment = .center
            toastLabel.font = UIFont.systemFont(ofSize: 14.0)
            toastLabel.text = message
            toastLabel.clipsToBounds  =  true
            toastLabel.numberOfLines = 0
            
            toastContainer.addSubview(toastLabel)
            window.addSubview(toastContainer)
            
            toastLabel.translatesAutoresizingMaskIntoConstraints = false
            toastContainer.translatesAutoresizingMaskIntoConstraints = false
            
            let a1 = NSLayoutConstraint(item: toastLabel, attribute: .leading, relatedBy: .equal, toItem: toastContainer, attribute: .leading, multiplier: 1.0, constant: 20.0)
            let a2 = NSLayoutConstraint(item: toastLabel, attribute: .trailing, relatedBy: .equal, toItem: toastContainer, attribute: .trailing, multiplier: 1.0, constant: -20.0)
            let a3 = NSLayoutConstraint(item: toastLabel, attribute: .bottom, relatedBy: .equal, toItem: toastContainer, attribute: .bottom, multiplier: 1.0, constant: -15.0)
            let a4 = NSLayoutConstraint(item: toastLabel, attribute: .top, relatedBy: .equal, toItem: toastContainer, attribute: .top, multiplier: 1.0, constant: 15.0)
            toastContainer.addConstraints([a1, a2, a3, a4])
            
            let c1 = NSLayoutConstraint(item: toastContainer, attribute: .centerX, relatedBy: .equal, toItem: window, attribute: .centerX, multiplier: 1.0, constant: 0.0)
            let c2 = NSLayoutConstraint(item: toastContainer, attribute: .centerY, relatedBy: .equal, toItem: window, attribute: .centerY, multiplier: 1.75, constant: 0.0)
            let c3 = NSLayoutConstraint(item: toastContainer, attribute: .width, relatedBy: .lessThanOrEqual, toItem: window, attribute: .width, multiplier: 0.9, constant: 0.0)
            window.addConstraints([c1, c2, c3])
            
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseIn, animations: {
                toastContainer.alpha = 1.0
            }, completion: { _ in
                guard !isPermanent else {
                    return
                }
                
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(NotificationUtils.hideView(_:)))
                toastContainer.addGestureRecognizer(tapGestureRecognizer)
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration, execute: {
                    NotificationUtils.hideView(tapGestureRecognizer)
                })
            })
        }
    }
    
    @objc private static func hideView(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let sender = gestureRecognizer.view else {
            print("Failed to get the container view for the Gesture Recognizer")
            return
        }
        
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        if (sender.isDescendant(of: window)) {
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
                sender.alpha = 0.0
            }, completion: {_ in
                sender.removeFromSuperview()
            })
        }
    }
    
    public static func hideToast() {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              let toastView = window.viewWithTag(1234) else {
            return
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
            toastView.alpha = 0.0
        }, completion: {_ in
            toastView.removeFromSuperview()
        })
    }
}
