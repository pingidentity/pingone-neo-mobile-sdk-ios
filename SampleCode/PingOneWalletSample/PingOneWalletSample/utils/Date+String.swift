//
//  Date+String.swift
//  PingOneWalletSample
//
//

import Foundation

extension Date {
    
    static func fromString(inputFormat: String, inputDate: String) -> Date? {
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.dateFormat = inputFormat
        return formatter.date(from: inputDate)
    }
    
    func toString(outputFormat: String) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.dateFormat = outputFormat
        return formatter.string(from: self)
    }
    
}
