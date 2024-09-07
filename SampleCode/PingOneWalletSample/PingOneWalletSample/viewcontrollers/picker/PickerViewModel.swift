//
//  PickerViewModel.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import DIDSDK
import PingOneWallet

public class PickerViewModel: BaseViewModel {
    
    public var pingOneWalletHelper: PingOneWalletHelper
    
    private var headerLabel: String! = "You have multiple credentials matching the criteria in the request."
    private var pickerItems: [PickerItem] = []
    private var listener: PickerListener?
    
    public required init(pingOneWalletHelper: PingOneWalletHelper) {
        self.pingOneWalletHelper = pingOneWalletHelper
    }
    
    public func setHeaderLabel(_ headerLabel: String) {
        self.headerLabel = headerLabel
    }
    
    public func getHeaderLabel() -> String {
        return self.headerLabel
    }
    
    public func setPickerListener(_ listener: PickerListener) {
        self.listener = listener
    }
    
    public func setPickerItems(_ pickerItems: [PickerItem]) {
        self.pickerItems = pickerItems
    }
    
    public func getPickerItems() -> [PickerItem] {
        return self.pickerItems
    }
    
    public func getPickerItemAt(index: Int) -> PickerItem {
        return self.pickerItems[index]
    }
 
    public func onItemPicked(index: Int) {
        self.listener?.onItemPicked(index: index)
    }
    
    public func onCanceled() {
        self.listener?.onPickerCanceled()
    }
    
}
