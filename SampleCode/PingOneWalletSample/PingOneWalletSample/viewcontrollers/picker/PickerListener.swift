//
//  PickerListener.swift
//  PingOneWalletSample
//
//

import Foundation

public protocol PickerListener {
    
    func onItemPicked(index: Int)
    func onPickerCanceled()
    
}
