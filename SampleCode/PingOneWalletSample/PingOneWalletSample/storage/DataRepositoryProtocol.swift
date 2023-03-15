//
//  DataRepository.swift
//  PingOneWalletSample
//
//

import Foundation
import PingOneWallet
import DIDSDK

public protocol DataRepositoryProtocol {
    
    func saveProfile(_ profile: Profile)
    func getProfile() -> Profile?
    func saveSelfClaim(_ claim: Claim)
    func getSelfClaim() -> Claim?
    func saveClaim(_ claim: Claim)
    func getClaim(for id: String) -> Claim?
    func saveRevokedClaimReference(_ claimReference: ClaimReference)
    func getRevokedClaimReference(for id: String) -> ClaimReference?
    func isClaimRevoked(claimId: String) -> Bool
    func deleteClaim(_ claim: Claim)
    func deleteClaim(for id: String)
    func getAllClaims() -> [Claim]
    
}
