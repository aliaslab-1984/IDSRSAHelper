//
//  SwiftRSA.swift
//  DocumentReaderSDK
//
//  Created by Enrico on 27/10/2020.
//  Copyright © 2020 AliasLab SpA. All rights reserved.
//

import Foundation
import openssl_grpc

public final class BoringRSA {

    private var privateKeyPointer: UnsafeMutablePointer<FILE>?
    private var publicKeyPointer: UnsafeMutablePointer<FILE>?
    private var password: [CChar]
    
    public enum BoringError: Error {
        case invalidURL
        case invalidString
        case openSSLError(code: UInt32, message: String?)
        
        static func lastOpenSSLError() -> BoringError {
            let errCode = ERR_get_error()
            if let errChars = ERR_error_string(errCode, nil) {
                let errData = Data(bytes: errChars, count: 256)
                let errDesc = String(decoding: errData, as: UTF8.self)
                return BoringError.openSSLError(code: errCode, message: errDesc)
            } else {
                return BoringError.openSSLError(code: errCode, message: nil)
            }
        }
    }
    
    public init(passphrase: String) {
        self.password = passphrase.cString(using: .utf8)!
        
        OpenSSL_add_all_ciphers()
        OpenSSL_add_all_digests()
        OpenSSL_add_all_algorithms()
    }
    
    deinit {
        // Makes sure that all the opened files are actually closed.
        fclose(privateKeyPointer)
        fclose(publicKeyPointer)
    }
    
    // MARK: API
    
    public func privateKey(at url: URL?,
                           perform cryptoAction: CryptoAction,
                           for string: String,
                           stringFormat: StringFormat = .base64) throws -> Data {
        let data: Data
        switch stringFormat {
        case .base64:
            guard let base64Data = Data(base64Encoded: string) else {
                throw BoringError.invalidString
            }
            data = base64Data
        case .plain:
            guard let plainData = string.data(using: .utf8) else {
                throw BoringError.invalidString
            }
            data = plainData
        }
        
        return try privateKey(at: url, perform: cryptoAction, for: data)
    }
    
    public func privateKey(at url: URL?,
                           perform cryptAction: CryptoAction,
                           for data: Data) throws -> Data {
        
        let privateKey = try loadKey(.privateKey, at: url)
        
        defer {
            fclose(privateKeyPointer)
        }
        
        switch cryptAction {
        case .encrypt:
            return try privateEncrypt(privateKey, data: data)
        case .decrypt:
            return try privateDecrypt(privateKey, data: data)
        }
    }
    
    public func publicKey(at url: URL?,
                          perform cryptoAction: CryptoAction,
                          for string: String,
                          stringFormat: StringFormat = .base64) throws -> Data {
        let data: Data
        switch stringFormat {
        case .base64:
            guard let base64Data = Data(base64Encoded: string) else {
                throw BoringError.invalidString
            }
            data = base64Data
        case .plain:
            guard let plainData = string.data(using: .utf8) else {
                throw BoringError.invalidString
            }
            data = plainData
        }
        
        
        return try publicKey(at: url, perform: cryptoAction, for: data)
    }
    
    public func publicKey(at url: URL?,
                          perform cryptAction: CryptoAction,
                          for data: Data) throws -> Data {
        
        let publicKey = try loadKey(.publicKey, at: url)
        
        defer {
            fclose(publicKeyPointer)
        }
        
        switch cryptAction {
        case .encrypt:
            return try publicEncrypt(publicKey, data: data)
        case .decrypt:
            return try publicDecrypt(publicKey, data: data)
        }
    }
    
}

private extension BoringRSA {
    
    func loadKey(_ keyType: CryptographicKey,
                 at url: URL?) throws -> UnsafeMutablePointer<RSA> {
       guard let url = url else {
           throw BoringError.invalidURL
       }
       
       switch keyType {
       case .privateKey:
           self.privateKeyPointer = url.path.withCString { filePtr in
               return fopen(filePtr, "rb")
           }
           
           guard let privateKey = PEM_read_RSAPrivateKey(privateKeyPointer, nil, nil, &password) else {
               throw BoringError.lastOpenSSLError()
           }
           
           return privateKey
       case .publicKey:
           self.publicKeyPointer = url.path.withCString { filePtr in
               return fopen(filePtr, "rb")
           }
           
           guard let publicKey = PEM_read_RSA_PUBKEY(publicKeyPointer, nil, nil, nil) else {
               throw BoringError.lastOpenSSLError()
           }
           
           return publicKey
       }
   }
    
    func privateEncrypt(_ privateKey: UnsafeMutablePointer<RSA>,
                        data: Data) throws -> Data {
        let resSize = Int(RSA_size(privateKey))
        var encryptedDataBuffer = [UInt8](repeating: 0, count: resSize)
        
        var dataValues = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &dataValues, count: data.count)
        
        let size = RSA_private_encrypt(data.count, dataValues, &encryptedDataBuffer, privateKey, RSA_PKCS1_PADDING)
        if resSize != size {
            throw BoringError.lastOpenSSLError()
        }
        
        let encryptedSize = size >= 0 ? size : 0
        return Data(bytes: encryptedDataBuffer, count: Int(encryptedSize))
    }
    
    func privateDecrypt(_ privateKey: UnsafeMutablePointer<RSA>,
                        data: Data) throws -> Data {
        
        let resSize = Int(RSA_size(privateKey))
        var decryptedDataBuffer = [UInt8](repeating: 0, count: resSize)
        
        var dataValues = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &dataValues, count: data.count)
        
        let size = RSA_private_decrypt(data.count, dataValues, &decryptedDataBuffer, privateKey, RSA_PKCS1_PADDING)
        
        let decryptedSize = size >= 0 ? size : 0
        return Data(bytes: decryptedDataBuffer, count: Int(decryptedSize))
    }
    
    
    func publicDecrypt(_ publicKey: UnsafeMutablePointer<RSA>,
                       data: Data) throws -> Data {
        
        let resSize = Int(RSA_size(publicKey))
        var decryptedDataBuffer = [UInt8](repeating: 0, count: resSize)
        
        var dataValues = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &dataValues, count: data.count)
        
        let size = RSA_public_decrypt(data.count, dataValues, &decryptedDataBuffer, publicKey, RSA_PKCS1_PADDING)
        
        let decryptedSize = size >= 0 ? size : 0
        return Data(bytes: decryptedDataBuffer, count: Int(decryptedSize))
    }
    
    func publicEncrypt(_ publicKey: UnsafeMutablePointer<RSA>,
                       data: Data) throws -> Data {
        
        let resSize = Int(RSA_size(publicKey))
        var decryptedDataBuffer = [UInt8](repeating: 0, count: resSize)
        
        var dataValues = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &dataValues, count: data.count)
        
        let size = RSA_public_encrypt(data.count, dataValues, &decryptedDataBuffer, publicKey, RSA_PKCS1_PADDING)
        
        if resSize != size {
            throw BoringError.lastOpenSSLError()
        }
        
        let decryptedSize = size >= 0 ? size : 0
        return Data(bytes: decryptedDataBuffer, count: Int(decryptedSize))
    }
    
}
