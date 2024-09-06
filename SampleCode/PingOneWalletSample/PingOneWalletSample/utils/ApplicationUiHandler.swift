//
//  DefaultApplicationUiCallback.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit

public class ApplicationUiHandler {
    
    public func showConfirmationAlert(title: String, message: String, positiveActionTitle: String, cancelActionTitle: String, actionHandler: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let alertVc = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: positiveActionTitle, style: .default, handler: { _ in
                actionHandler(true)
                alertVc.dismiss(animated: false)
            }))
            alertVc.addAction(UIAlertAction(title: cancelActionTitle, style: .cancel, handler: { _ in
                actionHandler(false)
                alertVc.dismiss(animated: false)
            }))
            UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController?.present(alertVc, animated: true)
        }
    }
    
    public func showErrorAlert(title: String, message: String, actionTitle: String?, actionHandler: (() -> Void)?) {
        DispatchQueue.main.async {
            let alertVc = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertVc.addAction(UIAlertAction(title: actionTitle ?? "Okay", style: .default, handler: { _ in
                actionHandler?()
                alertVc.dismiss(animated: false)
            }))
            UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController?.present(alertVc, animated: true)
        }
    }
        
    // Toast methods
    
    public func showToast(message: String, hideAfter duration: TimeInterval) {
        self.showToast(message: message, duration: duration)
    }

    public func showToast(message: String) {
        self.showToast(message: message, duration: 0, isPermanent: true)
    }

    private func showToast(message: String, duration: TimeInterval, isPermanent: Bool = false) {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
                return
            }
            
            // Hide any previously visible toast messages before adding a new one
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
                
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(Self.hideView(_:)))
                toastContainer.addGestureRecognizer(tapGestureRecognizer)
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration, execute: {
                    Self.hideView(tapGestureRecognizer)
                })
            })
        }
    }
    
    public func hideToast() {
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
    
    // Utils methods
    
    public static func pushViewControllerOnTopVc(_ viewController: UIViewController) {
        let topViewController = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
        if let topNavController = topViewController as? UINavigationController {
            topNavController.pushViewController(viewController, animated: true)
        } else {
            topViewController?.present(viewController, animated: true)
        }
    }
    
    func openUrl(url: String, onComplete: @escaping (Bool, String) -> Void) {
        DispatchQueue.main.async {
            guard let redirectUri = URL(string: url),
                  UIApplication.shared.canOpenURL(redirectUri) else {
                onComplete(false, "Failed to process request")
                return
            }
            
            UIApplication.shared.open(redirectUri) { result in
                onComplete(result, result ? "Presentation request processed" : "Failed to process request")
            }
        }
    }
        
}
