//
//  CredentialDetailsViewController.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import PingOneWallet
import DIDSDK

class CredentialDetailsViewController: UIViewController {
    
    static let CELL_REUSE_IDENTIFIER = "CredentialDetailsCellItem"
    
    @IBOutlet weak var cardImage: UIImageView!
    @IBOutlet weak var claimsTableView: UITableView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var revokedLabel: UILabel!
    
    var actionLabel: String = "Confirm"
    var action: ((Claim?, CredentialDetailsViewController?) -> Void)?
    
    var credential: Claim!
    var sortedClaims: [(String, String)] = []
    
    static func initializeFor(credential: Claim, actionLabel: String, action: @escaping (Claim?, CredentialDetailsViewController?) -> Void) -> CredentialDetailsViewController? {
        let viewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "CredentialDetailsViewController") as? CredentialDetailsViewController
        viewController?.credential = credential
        viewController?.actionLabel = actionLabel
        viewController?.action = action
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.overrideUserInterfaceStyle = .light

        guard let credential = self.credential else {
            NotificationUtils.showErrorAlert(title: "Error", message: "Unable to retrieve details for the selected credential. Please restart the app and try again.", action: UIAlertAction(title: "Okay", style: .default, handler: { _ in
                self.navigationController?.dismiss(animated: true)
            }))
            return
        }

        let closeItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(self.onCloseClicked(_:)))
        self.navigationItem.leftBarButtonItem = closeItem
        
        self.cardImage.image = UIImage.fromClaim(credential, size: self.cardImage.bounds.size)
        self.setupTableView(credential)
        
        self.actionButton.setTitle(self.actionLabel, for: .normal)
        self.revokedLabel.isHidden = !DataRepository.shared.isClaimRevoked(claimId: credential.getId())
        
    }
    
    @objc func onCloseClicked(_ sender: UIBarButtonItem?) {
        self.action?(nil, self)
        self.navigationController?.popViewController(animated: true)
    }
    
    
    private func setupTableView(_ credential: Claim) {
        self.sortedClaims = credential.getData()
            .filter({ $0.key != ClaimKeys.cardImage })
            .map({ ($0.key, $0.value) })
            .sorted { $0.0 < $1.0 }
        
        self.claimsTableView.dataSource = self
        self.claimsTableView.delegate = self
        self.claimsTableView.register(UITableViewCell.self, forCellReuseIdentifier: CredentialDetailsViewController.CELL_REUSE_IDENTIFIER)
    }
    
    @IBAction func onActionClicked() {
        self.action?(self.credential, self)
        self.navigationController?.popViewController(animated: true)
    }
}


extension CredentialDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sortedClaims.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: CredentialDetailsViewController.CELL_REUSE_IDENTIFIER)
        
        if #available(iOS 14.0, *) {
            var content = cell.defaultContentConfiguration()
            content.text = self.sortedClaims[indexPath.item].0
            content.secondaryText = self.sortedClaims[indexPath.item].1
            cell.contentConfiguration = content
        } else {
            cell.textLabel?.text = self.sortedClaims[indexPath.item].0
            cell.detailTextLabel?.text = self.sortedClaims[indexPath.item].1
        }
        
        return cell
    }
    
}
