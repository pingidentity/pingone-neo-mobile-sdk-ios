//
//  CredentialPicker.swift
//  PingOneWalletSample
//
//

import Foundation
import DIDSDK
import PingOneWallet

public protocol CredentialPicker {
    
    func selectCredentialFor(presentationRequest: PresentationRequest, credentialMatcherResults: [CredentialMatcherResult], onResult: @escaping (_ result: CredentialsPresentation?) -> Void)
    
}

public protocol CredentialPickerListener {
    
    func onCredentialPicked(_ claim: Claim, keys: [String])
    func onPickerComplete()
    func onPickerCanceled()
    
}
