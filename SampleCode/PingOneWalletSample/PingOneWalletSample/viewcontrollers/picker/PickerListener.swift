//
//  PickerListener.swift
//  PingOneWalletSample
//
//

import Foundation
import DIDSDK

public protocol PickerListener {
    
    func onPickerComplete()
    func onPickerCanceled()
    
}

public protocol ClaimPickerListener: PickerListener {
    
    func onClaimPicked(_ claim: Claim, keys: [String])
    
}
