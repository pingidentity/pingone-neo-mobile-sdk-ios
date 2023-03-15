//
//  HomeViewController.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import PingOneWallet
import DIDSDK
import CryptoTools

class HomeViewController: UIViewController {
    
    @IBOutlet weak var waitOverlayView: UIView!
    @IBOutlet weak var welcomeView: UIView!
    @IBOutlet weak var homeView: UIView!
    
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileName: UILabel!
    
    @IBOutlet weak var credentialList: UITableView!
    
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var scanQrButton: UIButton!
    
    var sortedCredentials: [Claim] = []
    var profileCreationObserver, claimUpdatesObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.overrideUserInterfaceStyle = .light
        self.setNavBarAppearance()
        
        self.waitOverlayView.isHidden = false
        self.initializeStorage()
    }
    
    private func setNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "nav_bar_color") ?? UIColor(netHex: 0x2996CC)
        
        let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.buttonAppearance = buttonAppearance
        
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = self.navigationController?.navigationBar.standardAppearance
    }
    
    
    private func initializeStorage() {
        let errorHandler = UIApplication.shared.delegate as? AppDelegate
        DispatchQueue.global(qos: .userInitiated).async {
            StorageManager.initialize(errorHandler: errorHandler)
                .onResult { storageManager in
                    DataRepository.initializeWith(storageManager)
                    PingOneWalletHelper.initializeWallet(storageManager)
                        .onError { error in
                            logerror("PingOneWalletClient Builder error: \(error.localizedDescription)")
                            NotificationUtils.showErrorAlert(title: "Error", message: "Error initializing wallet. Please restart the app to try again.")
                        }
                        .onResult { _ in
                            DispatchQueue.main.async {
                                self.waitOverlayView.isHidden = true
                                self.profileCreationObserver = EventObserverUtils.observeProfileCreation { _ in
                                    EventObserverUtils.removeObserver(self.profileCreationObserver)
                                    self.initApp()
                                }
                                self.claimUpdatesObserver = EventObserverUtils.observeClaimUpdates(onUpdate: { claims in
                                    self.setupCredentialsList(claims)
                                })
                                
                                self.initApp()
                            }
                        }
                }
                .onError { error in
                    logerror("StorageInit error: \(error.localizedDescription)")
                    self.handleStorageInitError(error)
                }
        }
    }
    
    private func initApp() {
        guard let profile = DataRepository.shared.getProfile() else {
            self.homeView.isHidden = true
            self.welcomeView.isHidden = false
            return
        }
        self.welcomeView.isHidden = true
        self.homeView.isHidden = false
        self.setupProfileView(profile)
        self.setupCredentialsList(DataRepository.shared.getAllClaims())
        self.processAppOpenUrl()
    }
    
    private func processAppOpenUrl() {
        DispatchQueue.main.async {
            if let appOpenUrl = (UIApplication.shared.delegate as? AppDelegate)?.appOpenUrl {
                PingOneWalletHelper.shared.processQrContent(appOpenUrl)
                (UIApplication.shared.delegate as? AppDelegate)?.appOpenUrl = nil
            }
        }
    }
    
    private func setupProfileView(_ profile: Profile) {
        DispatchQueue.main.async {
            self.profileView.layer.borderColor = UIColor.darkGray.cgColor
            self.profileView.layer.borderWidth = 1.0
            self.profileImageView.image = profile.selfie
            self.profileName.text = profile.firstName + " " + profile.lastName
        }
    }
    
    
    private func setupCredentialsList(_ credentials: [Claim]) {
        DispatchQueue.main.async {
            self.sortedCredentials = credentials
            self.credentialList.delegate = self
            self.credentialList.dataSource = self
            self.credentialList.register(CredentialListItem.nib, forCellReuseIdentifier: CredentialListItem.CELL_REUSE_IDENTIFIER)
            self.credentialList.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        if identifier == "startQrScanner",
           let qrVc = segue.destination as? QRScannerViewController {
            qrVc.listener = self
        } else if identifier == "viewCredentialDetails",
                  let credential = sender as? Claim,
                  let detailsVc = segue.destination as? CredentialDetailsViewController {
            detailsVc.credential = credential
            detailsVc.actionLabel = "Delete Credential"
            detailsVc.action = { claim, _ in
                if let claim = claim {
                    DataRepository.shared.deleteClaim(claim)
                    PingOneWalletHelper.shared.reportCredentialDeletion(claim)
                    EventObserverUtils.broadcastClaimsUpdatedNotification()
                }
            }
        }
    }
    
    private func handleStorageInitError(_ error: Error) {
        if let passcodeError = error as? BiometryStateError {
            let message: String
            var title: String = "Authentication Error"
            switch passcodeError {
            case .passcodeNotSet:
                title = "Passcode Not Set"
                message = "You must set at least a device passcode in your phone's settings to use ShoCard."
            case .appCanceledAuthentication:
                message = "You must authenticate to initialize the application. Please restart the app to try again."
            case .cannotUseBiometry:
                message = "An error occurred during the authentication. Please restart the app to try again."
            case .deviceNotSupported:
                title = "Unsupported Device"
                message = "ShoCard requires a device that supports some form of biometric authentication. Please contact support from the App Store listing for further information."
            case .tooManyFailedAttempts:
                message = "Too many incorrect attempts. Please restart the app to try again."
            case .noEnrolledBiometry: //Won't get executed since biometry is not enforced and passcode is accepted to init secure enclave
                message = "Please enroll a biometric in the phone settings to use ShoCard."
            }
            NotificationUtils.showErrorAlert(title: title, message: message)
        } else {
            NotificationUtils.showErrorAlert(title: "Error", message: "Failed to initialize storage. App may behave abnormally. Please restart the app to try again.")
        }
    }
    
}

extension HomeViewController: QrScannerListener {
    
    func onQrScanned(_ rawQrContent: String) {
        print("QR Content: \(rawQrContent)")
        PingOneWalletHelper.shared.processQrContent(rawQrContent)
    }
    
    func onQrScannerCanceled() {
        print("QR scanner canceled.")
    }
    
    
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DataRepository.shared.getAllClaims().count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.view.bounds.width * 0.75
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let credentialItem = tableView.dequeueReusableCell(withIdentifier: CredentialListItem.CELL_REUSE_IDENTIFIER, for: indexPath) as? CredentialListItem else {
            return UITableViewCell()
        }
        let credential = self.sortedCredentials[indexPath.item]
        credentialItem.populate(credential: credential, isRevoked: DataRepository.shared.isClaimRevoked(claimId: credential.getId()))
        return credentialItem
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.performSegue(withIdentifier: "viewCredentialDetails", sender: self.sortedCredentials[indexPath.item])
    }
}
