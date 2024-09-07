//
//  PickerViewController.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit

public class PickerViewController: UIViewController, BaseViewController {
    
    public var walletCoordinator: WalletCoordinator!
    var viewModel: PickerViewModel!
    
    public func setViewModel<VM>(_ viewModel: VM) where VM : BaseViewModel {
        self.viewModel = (viewModel as! PickerViewModel)
    }
    
    private var headerTitle: String?
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var itemsTableView: UITableView!
    @IBOutlet weak var cancelButton: UIButton!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.overrideUserInterfaceStyle = .light
        
        self.presentationController?.delegate = self
        self.headerLabel.text = self.viewModel.getHeaderLabel()
        self.setTableView()
    }
        
    func setTableView() {
        self.itemsTableView.dataSource = self
        self.itemsTableView.delegate = self
        self.itemsTableView.register(ItemPickerTableViewCell.nib, forCellReuseIdentifier: ItemPickerTableViewCell.CELL_REUSE_IDENTIFIER)
    }
    
    @IBAction func onCancelClicked(_ sender: UIButton) {
        self.dismiss(animated: true) { [weak self] in
            self?.viewModel.onCanceled()
        }
    }
    
}

extension PickerViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.getPickerItems().count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ItemPickerTableViewCell.CELL_REUSE_IDENTIFIER, for: indexPath) as? ItemPickerTableViewCell else {
            let cell = UITableViewCell()
            cell.textLabel?.text = "!!Failed to load data!!"
            return cell
        }
        
        cell.populate(pickerItem: self.viewModel.getPickerItemAt(index: indexPath.item))
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.viewModel.onItemPicked(index: indexPath.item)
            self.dismiss(animated: true)
        }
    }
    
}

extension PickerViewController: UIAdaptivePresentationControllerDelegate {
    
    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
    
    public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        self.viewModel.onCanceled()
        self.dismiss(animated: true)
    }
    
}
