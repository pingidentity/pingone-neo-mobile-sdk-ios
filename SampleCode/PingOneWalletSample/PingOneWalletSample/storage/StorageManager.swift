//
//  StorageManager.swift
//  PingOneWalletSample
//
//

import Foundation
import PingOneWallet
import DIDSDK
import CryptoTools

public class StorageManager: StorageManagerContract {
    
    static let APP_STORAGE_KEY = "app_unique_id_storage_key"
    static let APPLICATION_INSTANCE_STORAGE_KEY = "application_instance_storage_key"
    static let CLAIM_STORAGE_KEY: String = "claim_storage_key"
    static let CLAIM_REFERENCE_STORAGE_KEY: String = "claim_reference_storage_key"
    
    static let SELF_CLAIMS_STORAGE_KEY: String = "self_claims_storage_key"
    static let CLAIMS_STORAGE_KEY: String = "claims_storage_key"
    static let UNSOLICITED_CLAIMS_STORAGE_KEY: String = "unsolicited_claims_storage_key"
    static let REVOKED_CLAIMS_STORAGE_KEY: String = "revoked_claims_storage_key"
        
    public static func initialize(errorHandler: StorageErrorHandler?) -> CompletionHandler<StorageManager> {
        let completionHandler = CompletionHandler<StorageManager>()
        DispatchQueue.global(qos: .userInitiated).async {
            let defaultsCompletionHandler: (Result<EncryptedKeyStruct, Error>) -> Void = { result in
                switch result {
                case .failure(let e):
                    completionHandler.setError(e)
                case .success(let eKey):
                    //eKey: Key used to encrypt data in defaults, this symm key is stored encrypted in secure enclave
                    do {
                        try saveEncryptedKey(StorageKey(keyStruct: eKey))
                        completionHandler.setResult(StorageManager(try AES256(key: eKey.decryptedKey), errorHandler: errorHandler))
                    } catch {
                        completionHandler.setError(error)
                    }
                }
            }
            
            if let storageKey = try? retrieveEncryptedKey() {
                EncryptedDefaults.initialize(uniqueId: storageKey.uniqueId, encryptedKey: storageKey.encryptedKey, onComplete: defaultsCompletionHandler)
            } else {
                EncryptedDefaultsConfigurator().useSecureEnclave(true).initialize(onComplete: defaultsCompletionHandler)

            }
        }
        return completionHandler
    }
    
    private static func saveEncryptedKey(_ key: StorageKey) throws {
        let keyJson = try JSONEncoder().encode(key)
        UserDefaults.standard.set(keyJson, forKey: StorageManager.APP_STORAGE_KEY)
    }
    
    private static func retrieveEncryptedKey() throws -> StorageKey? {
        guard let keyJson = UserDefaults.standard.data(forKey: StorageManager.APP_STORAGE_KEY) else {
            return nil
        }
        return try JSONDecoder().decode(StorageKey.self, from: keyJson)
    }
    
    private let encryptedFilesHelper: EncryptedFilesHelper
    var errorHandler: StorageErrorHandler?
    
    private init(_ symmetricCrypter: SymmetricCrypter, errorHandler: StorageErrorHandler?) {
        self.encryptedFilesHelper = EncryptedFilesHelper(symmetricCrypter: symmetricCrypter)
        self.errorHandler = errorHandler
    }
    
    public func setErrorHandler(errorHandler: StorageErrorHandler) {
        self.errorHandler = errorHandler
    }
    
    public func getEncryptedFilesHelper() -> EncryptedFilesHelper {
        return self.encryptedFilesHelper
    }
    
    public func saveApplicationInstance(_ applicationInstance: ApplicationInstance) {
        do {
            let appInstanceJson = try applicationInstance.toJsonString()
            try self.encryptedFilesHelper.saveToFile(string: appInstanceJson, for: StorageManager.APPLICATION_INSTANCE_STORAGE_KEY)
        } catch {
            self.errorHandler?.handleStorageError(StorageError.cannotStoreValueForKey(key: StorageManager.APPLICATION_INSTANCE_STORAGE_KEY, value: nil, debugDescripton: "Failed to save app instance", underlyingError: error))
        }
    }
    
    public func getApplicationInstance() -> ApplicationInstance? {
        do {
            guard let appInstanceJson = try self.encryptedFilesHelper.readFromFile(StorageManager.APPLICATION_INSTANCE_STORAGE_KEY) else {
                self.errorHandler?.handleStorageError(StorageError.cannotRetrieveValueForKey(key: StorageManager.APPLICATION_INSTANCE_STORAGE_KEY, debugDescripton: "Failed to retrieve app instance json", underlyingError: nil))
                return nil
            }
            
            return try ApplicationInstance(jsonString: appInstanceJson)
        } catch {
            self.errorHandler?.handleStorageError(StorageError.cannotRetrieveValueForKey(key: StorageManager.APPLICATION_INSTANCE_STORAGE_KEY, debugDescripton: "Failed to retrieve app instance json", underlyingError: error))
        }
        
        return nil
    }
    
    public func saveClaim(_ claim: Claim) {
        do {
            let claimJson = try claim.toJsonString()
            try self.encryptedFilesHelper.saveToFile(string: claimJson, for: self.getKeyForClaimId(claim.getId()))
        } catch {
            self.errorHandler?.handleStorageError(StorageError.cannotStoreValueForKey(key: getKeyForClaimId(claim.getId()), value: nil, debugDescripton: "Failed to save claim", underlyingError: error))
        }
    }
    
    public func getClaim(claimId: String) -> Claim? {
        do {
            guard let claimJson = try encryptedFilesHelper.readFromFile(self.getKeyForClaimId(claimId)) else {
                self.errorHandler?.handleStorageError(StorageError.cannotRetrieveValueForKey(key: getKeyForClaimId(claimId), debugDescripton: "Failed to retrieve claim json", underlyingError: nil))
                return nil
            }
            
            return try Claim(jsonString: claimJson)
        } catch {
            self.errorHandler?.handleStorageError(StorageError.cannotRetrieveValueForKey(key: getKeyForClaimId(claimId), debugDescripton: "Failed to retrieve claim json", underlyingError: error))
        }
        
        return nil
    }
    
    public func deleteClaim(_ claimId: String) {
        do {
            try self.encryptedFilesHelper.deleteFile(withName: self.getKeyForClaimId(claimId))
        } catch {
            self.errorHandler?.handleStorageError(StorageError.cannotDeleteKey(key: getKeyForClaimId(claimId), debugDescripton: "Failed to delete claim", underlyingError: error))
        }
    }
    
    public func getClaims() -> [Claim] {
        let claimIds = self.getStringSet(for: StorageManager.CLAIMS_STORAGE_KEY)
        return claimIds.compactMap { getClaim(claimId: $0) }
    }
    
    public func saveClaimReference(_ claimReference: ClaimReference) {
        do {
            let claimReferenceJson = try claimReference.toJsonString()
            try self.encryptedFilesHelper.saveToFile(string: claimReferenceJson, for: self.getKeyForClaimReference(claimReference.getId()))
        } catch {
            self.errorHandler?.handleStorageError(StorageError.cannotStoreValueForKey(key: getKeyForClaimReference(claimReference.getId()), value: nil, debugDescripton: "Failed to save claim reference", underlyingError: error))
        }
    }
    
    public func getClaimReference(claimId: String) -> ClaimReference? {
        do {
            guard let claimReferenceJson = try encryptedFilesHelper.readFromFile(self.getKeyForClaimId(claimId)) else {
                self.errorHandler?.handleStorageError(StorageError.cannotRetrieveValueForKey(key: getKeyForClaimReference(claimId), debugDescripton: "Failed to retrieve claim reference json", underlyingError: nil))
                return nil
            }
            
            return try ClaimReference(jsonString: claimReferenceJson)
        } catch {
            self.errorHandler?.handleStorageError(StorageError.cannotRetrieveValueForKey(key: getKeyForClaimReference(claimId), debugDescripton: "Failed to retrieve claim json", underlyingError: error))
        }
        
        return nil
    }
    
    
    public func saveStringSet(_ set: [String], for key: String) {
        guard EncryptedDefaults.standard.set(set, forKey: key) else {
            self.errorHandler?.handleStorageError(StorageError.cannotStoreValueForKey(key: key, value: nil, debugDescripton: "Failed to save string set", underlyingError: nil))
            return
        }
    }
    
    public func getStringSet(for key: String) -> [String] {
        guard let result = EncryptedDefaults.standard.array(forKey: key) as? [String] else {
            self.errorHandler?.handleStorageError(StorageError.cannotRetrieveValueForKey(key: key, debugDescripton: "Failed to retrieve string set", underlyingError: nil))
            return []
        }
        return result
    }
    
    public func saveString(_ str: String, for key: String) {
        EncryptedDefaults.standard.set(str, forKey: key)
    }
    
    public func getString(for key: String) -> String? {
        return EncryptedDefaults.standard.string(forKey: key)
    }
    
    private func getKeyForClaimReference(_ claimId: String) -> String {
        return "\(StorageManager.CLAIM_REFERENCE_STORAGE_KEY)_\(claimId)"
    }
    
    private func getKeyForClaimId(_ claimId: String) -> String {
        return "\(StorageManager.CLAIM_STORAGE_KEY)_\(claimId)"
    }
    
    private func getFilesURL() -> URL {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filesUrl = documentsUrl.appendingPathComponent("files")
        do {
            try FileManager.default.createDirectory(at: filesUrl, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            logerror(error.localizedDescription)
        }
        return filesUrl
    }
    
    private func getFileUrlFor(fileName: String) -> URL? {
        let fileURL = getFilesURL().appendingPathComponent(fileName)
        return fileURL
    }
    
    
}

public struct StorageKey: Codable {
    public let encryptedKey: Data
    public let uniqueId: String
    
    init(encryptedKey: Data, uniqueId: String) {
        self.encryptedKey = encryptedKey
        self.uniqueId = uniqueId
    }
    
    init(keyStruct: EncryptedKeyStruct) {
        self.encryptedKey = keyStruct.encryptedKey
        self.uniqueId = keyStruct.uniqueId
    }
}

public protocol StorageErrorHandler {
    
    func handleStorageError(_ error: StorageError)
    
}

public enum StorageError: Error, LocalizedError {
    
    case jsonEncodingFailed(underlyingError: Error?)
    case jsonDecodingFailed(underlyingError: Error?)
    case encryptionFailed(underlyingError: Error?)
    case decryptionFailed(underlyingError: Error?)
    case cannotAccessFileStorage(underlyingError: Error?)
    case cannotDeleteKey(key: String, debugDescripton: String?, underlyingError: Error?)
    case cannotStoreValueForKey(key: String, value: String?, debugDescripton: String?, underlyingError: Error?)
    case cannotRetrieveValueForKey(key: String, debugDescripton: String?, underlyingError: Error?)
    
    public var underlyingError: Error? {
        switch self {
        case .cannotAccessFileStorage(let underlyingError):
            return underlyingError
        case .cannotDeleteKey(_, _, let underlyingError),
                .cannotRetrieveValueForKey(_, _, let underlyingError),
                .cannotStoreValueForKey(_, _, _, let underlyingError):
            return underlyingError
        default:
            return nil
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .jsonEncodingFailed(let underlyingError):
            return underlyingError?.localizedDescription ?? "Failed to encode to json"
        case .jsonDecodingFailed(let underlyingError):
            return underlyingError?.localizedDescription ?? "Failed to decode json"
        case .encryptionFailed(let underlyingError):
            return underlyingError?.localizedDescription ?? "Failed to encrypt content"
        case .decryptionFailed(let underlyingError):
            return underlyingError?.localizedDescription ?? "Failed to decrypt content"
        case .cannotAccessFileStorage(let underlyingError):
            return underlyingError?.localizedDescription ?? "Cannot access file storage system to save file"
        case .cannotDeleteKey(let key, let debugDescripton, let underlyingError):
            return "Cannot delete key. Key: \(key) - \(debugDescripton ?? "") - underlying error: \(underlyingError?.localizedDescription ?? "none")"
        case .cannotStoreValueForKey(let key, let value, let debugDescripton, let underlyingError):
            return "Cannot save value. Key: \(key), Value: \(value ?? "Not available") - \(debugDescripton ?? "") - underlying error: \(underlyingError?.localizedDescription ?? "none")"
        case .cannotRetrieveValueForKey(let key, let debugDescripton, let underlyingError):
            return "Cannot retrieve value. Key: \(key) - \(debugDescripton ?? "") - underlying error: \(underlyingError?.localizedDescription ?? "none")"
        }
    }
    
}
