//
//  DataRepository.swift
//  PingOneWalletSample
//
//

import Foundation
import DIDSDK

public class DataRepository: DataRepositoryProtocol {
    
    static let PROFILE_STORAGE_KEY = "profile_storage_key"
    static let PROFILE_SELF_CLAIM_STORAGE_KEY = "profile_self_claim_storage_key"
    
    var profile: Profile?
    var applicationInstance: ApplicationInstance!
    var claimIds: [String] = []
    var revokedClaimIds: [String] = []
    
    var claims: [String: Claim] = [:]
    var revokedClaims: [String: ClaimReference] = [:]
    
    var storageManager: StorageManager!
    
    public static var shared: DataRepository!
    
    public static func initializeWith(_ storageManager: StorageManager) {
        if let _ = shared {
            shared.storageManager = storageManager
        } else {
            shared = DataRepository(storageManager)
        }
        shared.reload()
    }
    
    private init(_ storageManager: StorageManager) {
        self.storageManager = storageManager
    }
    
    public func saveProfile(_ profile: Profile) {
        do {
            let profileJson = try JSONEncoder().encode(profile).toString()
            try self.storageManager.getEncryptedFilesHelper().saveToFile(string: profileJson, for: DataRepository.PROFILE_STORAGE_KEY)
        } catch {
            self.storageManager.errorHandler?.handleStorageError(StorageError.cannotStoreValueForKey(key: DataRepository.PROFILE_STORAGE_KEY, value: nil, debugDescripton: "Cannot save profile", underlyingError: error))
        }
    }
    
    public func getProfile() -> Profile? {
        do {
            guard let profileJson = try self.storageManager.getEncryptedFilesHelper().readFromFile(DataRepository.PROFILE_STORAGE_KEY) else {
                self.storageManager.errorHandler?.handleStorageError(StorageError.cannotRetrieveValueForKey(key: DataRepository.PROFILE_STORAGE_KEY, debugDescripton: "Cannot retrieve profile", underlyingError: nil))
                return nil
            }
            return try JSONDecoder().decode(Profile.self, from: profileJson.toData())
        } catch {
            self.storageManager.errorHandler?.handleStorageError(StorageError.cannotRetrieveValueForKey(key: DataRepository.PROFILE_STORAGE_KEY, debugDescripton: "Cannot retrieve profile", underlyingError: error))
        }
        return nil
    }
    
    public func saveSelfClaim(_ claim: Claim) {
        self.storageManager.saveClaim(claim)
        self.storageManager.saveString(claim.getId(), for: DataRepository.PROFILE_SELF_CLAIM_STORAGE_KEY)
    }
    
    public func getSelfClaim() -> Claim? {
        if let claimId = self.storageManager.getString(for: DataRepository.PROFILE_SELF_CLAIM_STORAGE_KEY) {
            return self.storageManager.getClaim(claimId: claimId)
        }
        return nil
    }
    
    public func saveClaim(_ claim: Claim) {
        self.storageManager.saveClaim(claim)
        self.claimIds.append(claim.getId())
        self.storageManager.saveStringSet(self.claimIds, for: StorageManager.CLAIMS_STORAGE_KEY)
    }
    
    public func getClaim(for id: String) -> Claim? {
        if let claim = self.claims[id] {
            return claim
        }
        
        if let claim = self.storageManager.getClaim(claimId: id) {
            self.claims[claim.getId()] = claim
            return claim
        }
        
        return nil
    }
    
    public func saveRevokedClaimReference(_ claimReference: ClaimReference) {
        self.storageManager.saveClaimReference(claimReference)
        self.revokedClaimIds.append(claimReference.getId())
        self.storageManager.saveStringSet(self.revokedClaimIds, for: StorageManager.REVOKED_CLAIMS_STORAGE_KEY)
    }
    
    public func getRevokedClaimReference(for id: String) -> ClaimReference? {
        if let claimReference = self.revokedClaims[id] {
            return claimReference
        }
        
        if let claimReference = self.storageManager.getClaimReference(claimId: id) {
            self.revokedClaims[claimReference.getId()] = claimReference
            return claimReference
        }
        
        return nil
    }
    
    public func isClaimRevoked(claimId: String) -> Bool {
        guard (self.revokedClaimIds.contains(claimId)) else {
            return false
        }
        let revokedClaimReference = self.revokedClaims[claimId] ?? self.getRevokedClaimReference(for: claimId)
        return revokedClaimReference != nil
    }
    
    public func deleteClaim(_ claim: Claim) {
        self.deleteClaim(for: claim.getId())
    }
    
    public func deleteClaim(for id: String) {
        storageManager.deleteClaim(id)
        
        self.claimIds.removeAll { $0 == id }
        self.storageManager.saveStringSet(self.claimIds, for: StorageManager.CLAIMS_STORAGE_KEY)
        
        self.claims.removeValue(forKey: id)
    }
    
    public func getAllClaims() -> [Claim] {
        for claimId in self.claimIds {
            _ = self.getClaim(for: claimId)
        }
        
        return self.claims.values.sorted { c1, c2 in
            guard let c1Date = c1.getCreateDate().toDateFromISO8601,
                  let c2Date = c2.getCreateDate().toDateFromISO8601 else {
                return true
            }
            return c1Date.compare(c2Date) == .orderedDescending
        }
    }
    
    private func reload() {
//        try? self.storageManager.getEncryptedFilesHelper().deleteFile(withName: DataRepository.PROFILE_STORAGE_KEY)
        self.profile = getProfile()
        self.applicationInstance = storageManager.getApplicationInstance()
        self.claimIds = storageManager.getStringSet(for: StorageManager.CLAIMS_STORAGE_KEY)
        self.revokedClaimIds = storageManager.getStringSet(for: StorageManager.REVOKED_CLAIMS_STORAGE_KEY)
    }
    
    
}
