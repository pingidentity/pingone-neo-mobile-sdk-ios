//
//  CredentialDetailsView.swift
//  PingOneWalletSample
//
//

import Foundation

public class CredentialDetailsView: BaseView<CredentialDetailsViewModel, CredentialDetailsViewController> {
    
    func setCredentialAction(_ credentialAction: CredentialDetailsViewAction) {
        self.viewModel.setCredentialAction(credentialAction)
    }
    
}

public enum CredentialDetailsViewAction {
    
    case ACCEPT, DELETE
    
    var buttonLabel: String {
        switch self {
        case .ACCEPT:
            return "Accept Credential"
        case .DELETE:
            return "Delete Credential"
        }
    }
}
