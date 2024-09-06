//
//  CredentialDetailsViewController.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit

public class CredentialDetailsViewController: UIViewController, BaseViewController {
    
    var viewModel: CredentialDetailsViewModel!
    public var walletCoordinator: WalletCoordinator!
    
    public func setViewModel<VM>(_ viewModel: VM) where VM : BaseViewModel {
        self.viewModel = (viewModel as! CredentialDetailsViewModel)
    }
    
    static let CELL_REUSE_IDENTIFIER = "CredentialDetailsCellItem"
    
    @IBOutlet weak var cardImage: UIImageView!
    @IBOutlet weak var claimsTableView: UITableView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var revokedLabel: UILabel!
    @IBOutlet weak var issuerDetailsView: IssuerDetailsView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.overrideUserInterfaceStyle = .light
        
        self.updateNavigationBar()
        
        self.cardImage.image = self.viewModel.getCredentialImage(forSize: self.cardImage.bounds.size)
        
        self.setClaimsList()
        self.setIssuerMetadata()
        self.setActionLabel()
        self.revokedLabel.isHidden = !self.viewModel.isRevoked()
    }
    
    func updateNavigationBar() {
        let closeItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(self.onCloseClicked(_:)))
        self.navigationItem.leftBarButtonItem = closeItem
    }
    
    @objc func onCloseClicked(_ sender: UIBarButtonItem?) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func setActionLabel() {
        self.actionButton.setTitle(self.viewModel.getCredentialAction().buttonLabel, for: .normal)
    }
    
    func setIssuerMetadata() {
        self.viewModel.getIssuerMetadata()
            .onResult { issuerMetadata in
                DispatchQueue.main.async {
                    guard !issuerMetadata.isEmpty() else {
                        self.issuerDetailsView.isHidden = true
                        return
                    }
                    self.issuerDetailsView.populate(issuerMetadata)
                }
            }
            .onError { error in
                print("Failed to load issuer metadata: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.issuerDetailsView.isHidden = true
                }
            }
    }
    
    private func setClaimsList() {
        self.claimsTableView.dataSource = self
        self.claimsTableView.delegate = self
        self.claimsTableView.register(UITableViewCell.self, forCellReuseIdentifier: CredentialDetailsViewController.CELL_REUSE_IDENTIFIER)
    }
    
    @IBAction func onActionClicked() {
        if (self.viewModel.getCredentialAction() == .DELETE) {
            self.walletCoordinator.showConfirmationAlert(title: "Delete Credential", message: "Are you sure you want to delete this credential?", positiveActionTitle: "Confirm", cancelActionTitle: "Cancel") { isPositiveAction in
                if (isPositiveAction) {
                    self.viewModel.performAction()
                }
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}


extension CredentialDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.getSortedClaims().count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: CredentialDetailsViewController.CELL_REUSE_IDENTIFIER)
        
        if #available(iOS 14.0, *) {
            var content = cell.defaultContentConfiguration()
            content.text = self.viewModel.getClaimFor(index: indexPath.item).0
            content.secondaryText = self.viewModel.getClaimFor(index: indexPath.item).1
            cell.contentConfiguration = content
        } else {
            cell.textLabel?.text = self.viewModel.getClaimFor(index: indexPath.item).0
            cell.detailTextLabel?.text = self.viewModel.getClaimFor(index: indexPath.item).1
        }
        
        return cell
    }
    
}
