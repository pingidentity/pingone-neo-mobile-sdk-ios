//
//  DateUtils.swift
//  PingOneWalletSample
//
//

import Foundation
import DIDSDK
import PingOneWallet

class DateUtils {
    
    static func getIssueDate(from claim: Claim) -> String? {
        return getDisplayStringFromISO8691(claim.getCreateDate())
    }
    
    static func getDisplayStringFromISO8691(_ iso8601Str: String) -> String? {
        guard let date = ISO8601DateFormatter().date(from: iso8601Str) else {
            return nil
        }
        return date.toString(outputFormat: "MMM dd, yyyy")
    }
    
}
