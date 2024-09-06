//
//  HomeViewController2.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit

public class HomeViewController: UIViewController, BaseViewController {
    
    var viewModel: HomeViewModel!
    public var walletCoordinator: WalletCoordinator!
    
    public func setViewModel<VM>(_ viewModel: VM) where VM : BaseViewModel {
        self.viewModel = (viewModel as! HomeViewModel)
    }
    
    @IBOutlet weak var pairButton: UIButton!
    @IBOutlet weak var scanQrButton: UIButton!
    @IBOutlet weak var credentialList: UITableView!
    
    private let refreshCredentialsControl = UIRefreshControl()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.overrideUserInterfaceStyle = .light
        self.setNavBarAppearance()
        
        self.setCredentialsList()
        self.refreshHomeView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.observeCredentialUpdates {
            self.refreshCredentialsList()
        }
    }
    
    func setCredentialsList() {
        self.credentialList.dataSource = self
        self.credentialList.delegate = self
        self.credentialList.register(CredentialListItemCell.nib, forCellReuseIdentifier: CredentialListItemCell.CELL_REUSE_IDENTIFIER)
        
        self.credentialList.addSubview(self.refreshCredentialsControl)
        self.refreshCredentialsControl.attributedTitle = NSAttributedString(string: "Checking for updates...")
        self.refreshCredentialsControl.addTarget(self, action: #selector(self.checkForUpdates), for: .valueChanged)
    }
    
    func refreshHomeView() {
        DispatchQueue.main.async {
            self.pairButton.isHidden = self.viewModel.getAllCredentials().count > 0
            self.credentialList.isHidden = !self.pairButton.isHidden
            self.scanQrButton.isHidden = !self.pairButton.isHidden
            
            //MARK: Comment if not using push notifications
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate, appDelegate.pnToken == nil {
                appDelegate.registerForAPNS()
            }
            
            guard !self.viewModel.isPollingEnabled() else {
                return
            }
            
            if (self.viewModel.getAllCredentials().isEmpty) {
                self.viewModel.pollForMessages()
            } else {
                self.viewModel.stopPolling()
            }
     
        }
    }
    
    func refreshCredentialsList() {
        DispatchQueue.main.async {
            self.refreshHomeView()
            self.credentialList.reloadData()
        }
    }
    
    @objc func checkForUpdates() {
        DispatchQueue.main.async {
            self.viewModel.checkForMessages()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.refreshCredentialsControl.endRefreshing()
            }
        }
    }
    
    @IBAction func onPairClicked(_ sender: UIButton) {
        self.walletCoordinator.showQrScanner()
    }
    
    @IBAction func onScanQrClicked(_ sender: UIButton) {
        self.walletCoordinator.showQrScanner()
    }
    
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.getAllCredentials().count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.view.bounds.width * 0.8
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let credentialItem = tableView.dequeueReusableCell(withIdentifier: CredentialListItemCell.CELL_REUSE_IDENTIFIER, for: indexPath) as? CredentialListItemCell else {
            return UITableViewCell()
        }
        let listItem = self.viewModel.getListItemFor(index: indexPath.item, size: credentialItem.getImageSize())
        credentialItem.populate(item: listItem)
        return credentialItem
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.walletCoordinator.pushCredentialDetails(self.viewModel.getCredentialFor(index: indexPath.item))
    }
}
