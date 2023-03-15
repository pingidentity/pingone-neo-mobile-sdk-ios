//
//  CreateProfileViewController.swift
//  PingOneWalletSample
//
//

import UIKit
import PingOneWallet
import CryptoTools

class CreateProfileViewController: UIViewController {
    
    @IBOutlet weak var selfieImageView: UIImageView!
    @IBOutlet var textFields: [UITextField]!
    @IBOutlet weak var createProfileButton: UIButton!
    
    private var textFieldCharCount: [Int] = Array(repeating: 0, count: 3)
    private var values: [String] = Array(repeating: "", count: 3)
    private let fieldNames = ["first name", "last name", "email"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.overrideUserInterfaceStyle = .light
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.endEditing)))
        self.textFields.forEach { $0.delegate = self }
        self.setupImageView()
    }
    
    @objc private func endEditing() {
        self.view.endEditing(true)
    }
    
    private func setupImageView() {
        self.selfieImageView.contentMode = .scaleAspectFill
        self.selfieImageView.layer.cornerRadius = 5
        self.selfieImageView.layer.borderColor = UIColor.darkGray.cgColor
        self.selfieImageView.layer.borderWidth = 2.0
    }
    
    @IBAction func onCaptureSelfieClicked(_ sender: UIButton) {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = false
        vc.delegate = self
        self.present(vc, animated: true)
    }
    
    @IBAction func onCreateProfileClicked(_ sender: UIButton) {
        for i in 0..<self.textFields.count {
            guard self.textFields[i].hasText, let value = self.textFields[i].text else {
                NotificationUtils.showErrorAlert(title: "Missing Information", message: "You must enter your \(self.fieldNames[i]) to create the profile.")
                return
            }
            values[i] = value
        }
        
        guard let selfie = self.selfieImageView.image else {
            NotificationUtils.showErrorAlert(title: "Missing Information", message: "You must capture your selfie to create the profile.")
            return
        }
        
        let profile = Profile(firstName: values[0], lastName: values[1], email: values[2], selfie: selfie)
        DataRepository.shared.saveProfile(profile)
        EventObserverUtils.broadcastProfileCreationNotification()
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onCancelClicked(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
        
}

extension CreateProfileViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage,
           let selfieThumbnail = image.fixOrientation()?.getThumbnail() {
            self.selfieImageView.image = selfieThumbnail
            picker.dismiss(animated: true, completion: nil)
        }
        
    }
    
}

extension CreateProfileViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let currIndex = self.textFields.firstIndex(of: textField) else {
            textField.endEditing(true)
            return true
        }
        
        if currIndex + 1 >= self.textFields.count {
            textField.endEditing(true)
//            self.onCreateProfileClicked(self.createProfileButton)
        } else {
            self.textFields[currIndex + 1].becomeFirstResponder()
        }
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard let currIndex = self.textFields.firstIndex(of: textField) else {
            return true
        }
        
        if let text = textField.text {
            textFieldCharCount[currIndex] = text.count
        }
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let currIndex = self.textFields.firstIndex(of: textField) else {
            return
        }
        
        if let text = textField.text {
            let textCount = abs(text.count - self.textFieldCharCount[currIndex])
            let isAutofill = textCount > 1 && !text.isEmpty
            if isAutofill {
                _ = self.textFieldShouldReturn(textField)
            }
            self.textFieldCharCount[currIndex] = text.count
        }
    }
    
}
