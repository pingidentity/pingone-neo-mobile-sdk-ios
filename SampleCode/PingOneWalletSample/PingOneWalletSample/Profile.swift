//
//  Profile.swift
//  PingOneWalletSample
//
//

import Foundation
import UIKit
import CryptoTools

public class Profile: Codable {
    
    var firstName: String!
    var lastName: String!
    var email: String!
    var selfie: UIImage?
    
    private enum CodingKeys: String, CodingKey {
        case firstName, lastName, email, selfie
    }
    
    init(firstName: String, lastName: String, email: String, selfie: UIImage) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.selfie = selfie
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.firstName = try values.decode(String.self, forKey: .firstName)
        self.lastName = try values.decode(String.self, forKey: .lastName)
        self.email = try values.decode(String.self, forKey: .email)
        let imageBase64 = try values.decode(String.self, forKey: .selfie)
        guard let imageData = Data(base64URLEncoded: imageBase64),
              let selfie = UIImage(data: imageData) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [CodingKeys.selfie], debugDescription: "Failed to decode selfie from base64 encoded string."))
        }
        self.selfie = selfie
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.firstName, forKey: .firstName)
        try container.encode(self.lastName, forKey: .lastName)
        try container.encode(self.email, forKey: .email)
        guard let imageBase64 = self.selfie?.jpegData(compressionQuality: 1.0)?.base64URLEncodedString() else {
            throw EncodingError.invalidValue("Selfie", EncodingError.Context(codingPath: [CodingKeys.selfie], debugDescription: "Failed to encode selfie to base64 string"))
        }
        try container.encode(imageBase64, forKey: .selfie)
    }

    func toDictionary() throws -> [String: String] {
        let json = try self.toJson()
        return try JSONDecoder().decode([String: String].self, from: json.toData())
        
    }
    
    func toJson() throws -> String {
        return try JSONEncoder().encode(self).toString()
    }
    
}
