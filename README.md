#  PingOne Wallet SDK for iOS Documentation

This document defines the usage and interfaces of the PingOne Wallet SDK for iOS used to interact with the backend services. The SDK provides the capabilities for the user to receive, save, and share credentials for identification and verification purposes.

##  Running the Sample App

####  Prerequisites

- Xcode 12 or greater
- iOS 13 or greater

####  Set up and clone or download
The sample app can not run on a simulator and works only on a device because the app uses the secure enclave and keychain for storing information and it also requires the camera to capture a selfie for profile creation. 
1.  Ensure your Xcode is set up with a provisioning profile and a signing certificate to be able to install the app on a device. See the Apple Xcode document  [Run an app on a device](https://help.apple.com/xcode/mac/current/#/dev5a825a1ca) for more information.
2.  Clone or download the [PingOne Wallet SDK for iOS sample code](https://github.com/pingidentity/pingone-verify-mobile-sdk-ios) to your machine and open the `PingOneWalletSample.xcodeproj` file located under the `PingOneWalletSample` directory.

You'll find all other XCFramework dependencies required for PingOne Wallet in the [`PingOneWalletSample/dependencies`](SDK) directory.

3.  To run the sample app, select the scheme `PingOneWalletSample` --> , and click the Run button.
​
##  Integrating PingOne Wallet SDK for iOS With Your App


###  Getting Started

####  Add the dependencies needed for your application

The PingOne Wallet SDK for iOS relies on XCFramework components. You'll need to add these to Xcode for use by your application.

1.  If you haven't done so already, clone or download the [PingOne Wallet SDK for iOS sample app](https://github.com/pingidentity/pingone-verify-mobile-sdk-ios). You'll find the XCFramework dependencies required for the PingOne Wallet iOS SDK in the `PingOneWalletSample/dependencies` directory.

2.  Add the .xcframework dependencies:
    
    a. Click on your target in the project navigator.

    b. Drag and drop all the xcframework dependencies to the section _Frameworks, Libraries, and Embedded Content_ in Xcode.

3. Add SVGKit via Swift Package Manager

    a. In Xcode go to `File` -> `Add Packages...` 

    b. Type `https://github.com/SVGKit/SVGKit` in the search bar. 

    c. Choose `Dependency Role` and download the dependency. 

###  Installation and configuration

#### Set up iOS push messaging

##### Prerequisites

Ensure you have the following information necessary to set up push notifications for your PingOne Wallet application:

- Key ID 
- Team ID
- Token .p8 file
- Bundle ID


See the Apple guide [Establishing a Token-Based Connection to APNs](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns) for more information.


Configure push notifications
    
1. See the PingOne documentation for [Adding an application - Native](https://docs.pingidentity.com/r/en-us/pingone/p1_add_app_worker) to register your wallet app.
    
2. After adding your wallet application, Go to Mobile -> Edit (📝) -> Configure for iOS -> Add Push Notifications
    
3. Upload your .p8 token and fill in the Key ID, Team ID and Bundle ID values.

4.  Save your changes.

See the PingOne documentation [Edit an application - Native](https://docs.pingidentity.com/csh?context=pingone_edit_application_native) for more information.

## Class Reference

Refer to the documentation [here](https://pingidentity.github.io/pingone-wallet-mobile-sdk-ios/documentation/pingonewallet)


## Integrate the SDK with no user interaction

The sample app is designed for the use case where the wallet SDK embedded in the application is paired with a PingOne environment by an explicit pairing request initiated by the PingOne environment. In that pairing process the PingOne environment admin sends an email to the user with a Universal Link to open the wallet application to complete the pairing.

This example illustrates how to integrate the digital wallet SDK with no user interaction (silent mode).

### Initialization and wallet pairing

The illustrated workflow is followed to instantiate a wallet SDK that triggers a pairing request from the app. We must instantiate the wallet SDK and get the applicationInstanceId, which is a UUID that uniquely identifies the wallet SDK instance in the app. This applicationInstanceId is sent to a server trusted by the app. The server in turns calls a PingOne API to initiate and silently complete the wallet pairing.

![workflow to silently integrate a wallet SDK with no user interaction](IntegrationExamples/BackgroundWalletPairing-Presentation.png)

#### Steps 1 and 2 - Get the applicationInstanceId

The illustrated workflow requires modification of the PingOneWalletHelper.swift file (at line 21 in the source file) to get the applicationInstanceId from the instantiated SDK to enable a backend pairing request.

This code requires that:

* The application has already established the user to which the wallet belongs using existing authentication means

* The application has a trusted service backend with which it can communicate.

```swift
    let clientBuilder = PingOneWalletClient.Builder(forRegion: PingOneRegion.NA)
    // set storage manager for easy manangement of encrypted storage
    if let storageManager = storageManager {
        clientBuilder.setStorageManager(storageManager)
    }
    // Using the builder pattern, once the clientBuilder is setup 
    clientBuilder.build()
        .onError { error in
            completionHandler.setError(error)
        }
        .onResult { client in
            // You need the applicationInstanceId for the instantiated 
            let applicationInstanceId = client.getApplicationInstance(forRegion: PingOneRegion.NA)?.getId()
            // Send this applicationInstanceId to a trusted service
            // to pair the wallet with the "user" in the application.
            ...
        }
```
#### Step 3 - Request pairing

Send a request to pair ``userId`` from the application with the applicationInstanceId of the wallet SDK. This requires custom code and the details depend on the application. Ping Identity recommends that mobile applications do not directly call the PingOne OAuth APIs.


#### Step 4 - Create a user and pair the wallet

Call the PingOne APIs to create a user in your PingOne environment and pair a digital wallet.

Create User API

    curl -X POST https://api.pingone.com/v1/environments/abfba8f6-49eb-49f5-a5d9-80ad5c98f9f6/users
    
Create digital wallet API

    curl -X POST https://api.pingone.com/v1/environments/abfba8f6-49eb-49f5-a5d9-80ad5c98f9f6/users/49825b76-e1df-4cdc-b973-0c580f1cb049/digitalWallets

with a body similar to
    
    Authorization: Bearer {{accessToken}}
    Content-type: application/json

    {
        "digitalWalletApplication": {
        "id": "{{digitalWalletApplicationID}}"
    },
        "applicationInstance": {
            "id": "{{applicationInstanceId}}"
        }
    }

#### Step 5 - Pairing request

PingOne sends a pairing request to the wallet SDK embedded in the user app identified by applicationInstanceId.

1. The pairing request contains a “cryptographically secure random challenge string” that the wallet SDK signs and returns to the PingOne credentials service.

2. PingOne credentials service sends an end-to-end encrypted message to the wallet SDK embedded in the user app. The PingOne Mailbox Service sends this message.

3. The wallet SDK inside the app polls the PingOne Mailbox service every 3 seconds. This is default behavior so there is no need to write additional code or make any modifications.

4. When the app receives the encrypted message from the PingOne Credentials service, it decrypts the message and calls the registered message handler as defined in PingOneWalletHelper.swift.

5. Code below is modified from PingOneWalletHelper.swift to ensure that no user interaction is required to complete the pairing process. This is a method in the WalletCallbackHandler swift protocol implemented in the PingOneWalletHelper.swift file.

```swift
    func handleCredentialRequest(_ presentationRequest: PresentationRequest) {
        guard let pairingRequest = presentationRequest.getPairingRequest() else {
            logerror("Wallet pairing failed: Invalid request for pairing")
            return
        }
        self.pingoneWalletClient.pairWallet(for: pairingRequest)
        .onResult({ _ in
            logattention("Wallet pairing successful")
        })
        .onError { err in
            logerror("Wallet pairing failed: \(err.localizedDescription)")
        }
        return        
        ...
    }
```

#### Step 6 - Wallet pairs

a. The call to SDK method pairWallet (on line 3) in the modified code responds to the pairing request and the app pairs with the user in the PingOne environment.

b. Step 6a in the illustrated workflow is the call to pairWallet.

c. Step 6b in the illustrated workflow is the feedback .onResult (on lines 4) and .onError (on line 7) in the modified code responds on success or failure of the message delivery for pairing.

### Issuance and revocation

To implement the credential issuance and revocation workflow requires changes to the sample app code.

#### Modify the sample app code
The sample app uses popup messages (also called toasts) to alert the user that the wallet SDK has received a notification about an issued credential or a revoked credential. You must modify the code to mute the popup messages and in the sample app.

#### Step 6 - Modify the sample app code
The illustrated workflow requires modification of the PingOneWalletHelper.swift file to not display a popup when a credential issuance request is received.

```swift
    func handleCredentialIssuance(issuer: String, 
                                  message: String?, 
                                  challenge: Challenge?, 
                                  claim: Claim, 
                                  errors: [PingOneWallet.WalletException]) -> Bool {
        logattention("Credential received: Issuer: \(issuer), 
                      message: \(message ?? "none")")
//        NotificationUtils.showToast(message: "Received a new credential")
        DataRepository.shared.saveCredential(claim)
//        EventObserverUtils.broadcastClaimsUpdatedNotification()
        return true
    }
    
    func handleCredentialRevocation(issuer: String, 
                                    message: String?,
                                    challenge: Challenge?,
                                    claimReference: ClaimReference, 
                                    errors: [PingOneWallet.WalletException]) -> Bool {
        logattention("Credential revoked: Issuer: \(issuer), message: \(message ?? "none")")
//        NotificationUtils.showToast(message: "Credential Revoked")
        DataRepository.shared.saveCredentialReference(claimReference)
//        EventObserverUtils.broadcastClaimsUpdatedNotification()
        return true
    }
```

#### Step 7 - Write to local storage

1. DataRepository defined in the DataRepository.swift has sample code to securely write to local application storage using the keys stored in the secure enclave.

2. You can always override the DataRepository implementation by writing your own classes that implement the DataRepositoryProtocol defined in the DataRepositoryProtocol.swift file.

3. You can always override the DataRepository implementation by writing your own classes that implement the DataRepositoryProtocol defined in the DataRepositoryProtocol.swift file.

#### Complete process for issuance and revocation

![credential issuance and revocation workflow](IntegrationExamples/BackgroundWalletPairing-IssuanceRevocation.png)

1. An API orchestration layer or an administrator using the Admin Console makes changes to user attributes in the user directory.

2. The PingOne Credentials Lifecycle Manager listens to directory change events and reviews the changes to determine if credentials must be issued or revoked based on credential issuance rules. If a credential needs to be issued or revoked the lifecycle manager makes entries in the staging area.

3. The PingOne Credentials API is invoked periodically to process all staged changes. The PingOne Credentials API issues or revokes credentials as determined by the Lifecycle Manager.

4. The credentials that are issued or revoked are bound to the wallet and are sent to the wallet using secure end-to-end encrypted messages using the Mailbox functionality of the PingOne Neo platform.

5. The Wallet SDK embedded inside the app polls the Mailbox API to check for new messages. The mailbox API returns newly issued or recently revoked credential message as an encrypted message meant for the SDK to read.

6. The Wallet SDK calls the app via the callback method handleCredentialIssuance or handleCredentialRevocation which the app has registered via the callback handler described earlier.

7. The User App handles the callback by storing the issued credential to or deleting the revoked credential from storage using storage manager implementation.

## Presentation

The sample app uses the PingOneWalletHelper class in PingOneWalletHelper.swift to handle links, QR code content, and push notification requests for presentation of credentials.

Following code is used to demonstrate how to handle the callback when the SDK receives a request to share a credential due to processing of a QR code, a deep link or a push notification request.

```swift
public func handleCredentialRequest(_ presentationRequest: PresentationRequest) {
    if (presentationRequest.isPairingRequest()) {
        self.handlePairingRequest(presentationRequest)
        return
    }
        
    let credentialMatcherResults = self.pingoneWalletClient.findMatchingCredentialsForRequest(presentationRequest).getResult()
    let matchingCredentials = credentialMatcherResults.filter { !$0.claims.isEmpty }
        
    guard !matchingCredentials.isEmpty else {
        // Handle no matching credential found in user's wallet
        return
    }
        
    // handle logic to select the credential to present 
    // if multiple matching credentials are found in the wallet.
    
    // handle presentation of the credentials (assuming that 
    // only one credential matched the wallet)
        
    self.pingoneWalletClient.presentCredentials(credentialPresentation).onResult { result in
        switch result.getPresentationStatus() {
        case .success:
            // Credential presentation successful
        case .failure:
            // Credential presentation failed
            logerror("Error sharing information: \(result.getDetails()?.debugDescription ?? "None")")
        case .requiresAction(let action):
            // Handle the action sent by the verifier 
            // for the wallet as response to the presentation
        }
    }
    .onError { err in
        logerror("Error sharing information: \(err.localizedDescription)")
    }
}
```
