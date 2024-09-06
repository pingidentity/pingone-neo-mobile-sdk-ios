//
//  LogoImageView.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit

public extension UIImageView {
    
    func loadFrom(_ urlString: String, defaultImage: UIImage? = nil) {
        if let url = URL(string: urlString) {
            DispatchQueue.global().async {
                guard let data = try? Data(contentsOf: url) else {
                    print("Cannot retrieve content from URL - \(urlString) ")
                    self.setImageOnMainQueue(image: defaultImage)
                    return
                }
                
                if let image = UIImage(data: data) {
                    self.setImageOnMainQueue(image: image)
                } else {
                    print("Failed to load a valid image from URL")
                    self.setImageOnMainQueue(image: defaultImage)
                }
                
            }
        } else { //Check if url is a base64 image
            print("Not a valid URL, checking if base64 encoded image")
            guard let data = Data(base64Encoded: urlString),
                  let image = UIImage(data:  data) else {
                print("Not a valid Base64 encoded image")
                self.setImageOnMainQueue(image: defaultImage)
                return
            }
            
            self.setImageOnMainQueue(image: image)
        }
    }
    
    private func setImageOnMainQueue(image: UIImage?) {
        DispatchQueue.main.async {
            self.image = image
        }
    }
    
}
