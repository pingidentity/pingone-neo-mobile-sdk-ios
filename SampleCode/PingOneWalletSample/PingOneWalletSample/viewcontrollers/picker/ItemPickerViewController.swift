//
//  ItemPickerViewController.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import PingOneWallet
import DIDSDK

class ItemPickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var headerTitle: String?
    private var tableViewContent: [PickerItem] = []
    private var onItemsSelected: ((Int?, ItemPickerViewController?) -> Void)?
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var itemsTableView: UITableView!
    
    static func getItemPicker(headerTitle: String?, tableViewContent: [PickerItem], onItemSelected: @escaping (_ selectedIndex: Int?, ItemPickerViewController?) -> Void) -> ItemPickerViewController? {
        let vc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "ItemPickerViewController") as? ItemPickerViewController
        vc?.headerTitle = headerTitle
        vc?.tableViewContent = tableViewContent
        vc?.onItemsSelected = onItemSelected
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.overrideUserInterfaceStyle = .light
        
        self.headerLabel.text = self.headerTitle ?? self.headerLabel.text
        self.itemsTableView.dataSource = self
        self.itemsTableView.delegate = self
        self.itemsTableView.register(ItemPickerTableViewCell.nib, forCellReuseIdentifier: ItemPickerTableViewCell.CELL_REUSE_IDENTIFIER)
        
        let backButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.onCloseClicked(_:)))
        self.navigationItem.leftBarButtonItem = backButton
    }
    
    @objc func onCloseClicked(_ sender: UIBarButtonItem?) {
        self.navigationController?.popViewController(animated: true)
        self.onItemsSelected?(nil, self)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewContent.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ItemPickerTableViewCell.CELL_REUSE_IDENTIFIER, for: indexPath) as? ItemPickerTableViewCell else {
            let cell = UITableViewCell()
            cell.textLabel?.text = "!!Failed to load data!!"
            return cell
        }
        
        cell.populate(pickerItem: self.tableViewContent[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            self.onItemsSelected?(indexPath.item, self)
        }
    }
    
}
