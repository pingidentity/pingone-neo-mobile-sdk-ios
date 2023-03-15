//
//  EncryptedFilesHelper.swift
//  PingOneWalletSample
//
//

import Foundation
import PingOneWallet
import CryptoTools

public class EncryptedFilesHelper {
    
    private let symmetricCrypter: SymmetricCrypter
    
    init(symmetricCrypter: SymmetricCrypter) {
        self.symmetricCrypter = symmetricCrypter
    }
    
    public func saveToFile(string: String, for fileName: String) throws {
        do {
            let url = try self.getFileUrlFor(fileName: fileName)
            let encryptedFile = try EncryptedFile.Builder()
                .setContent(value: string)
                .setUrl(value: url)
                .setCrypter(value: self.symmetricCrypter)
                .build()
            try encryptedFile.encrypt()
            try encryptedFile.write()
        } catch {
            throw StorageError.cannotStoreValueForKey(key: fileName, value: nil, debugDescripton: "Failed to save file", underlyingError: error)
        }
    }
    
    public func readFromFile(_ fileName: String) throws -> String? {
        do {
            let url = try self.getFileUrlFor(fileName: fileName)
            let encryptedFile = try EncryptedFile.Builder()
                .setUrl(value: url)
                .setCrypter(value: self.symmetricCrypter)
                .build()
            try encryptedFile.decrypt()
            return try encryptedFile.getContent()
        } catch {
            throw StorageError.cannotRetrieveValueForKey(key: fileName, debugDescripton: "Failed to retrieve file", underlyingError: error)
        }
    }
    
    public func deleteFile(withName fileName: String) throws {
        do {
            let url = try self.getFileUrlFor(fileName: fileName)
            try FileManager.default.removeItem(at: url)
        } catch {
            throw StorageError.cannotDeleteKey(key: fileName, debugDescripton: "Failed to delete file", underlyingError: error)
        }
    }
        
    private func getFilesURL() throws -> URL {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filesUrl = documentsUrl.appendingPathComponent("files")
        do {
            try FileManager.default.createDirectory(at: filesUrl, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw StorageError.cannotAccessFileStorage(underlyingError: error)
        }
        return filesUrl
    }
    
    private func getFileUrlFor(fileName: String) throws -> URL {
        let fileURL = try getFilesURL().appendingPathComponent(fileName)
        return fileURL
    }

}
