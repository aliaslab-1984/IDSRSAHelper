//
//  KeyPair.swift
//  IDSignQRGenerator
//
//  Created by Francesco Bianco on 23/12/21.
//

import Foundation
import Security

public struct KeyPair {
    public var publicKey: SecKey
    public var privateKey: SecKey
    
    public static func newPair(for appBundle: String) -> KeyPair? {
        let bundleString = appBundle.data(using: .utf8) ?? Data()
        let publicKeyAttribute: [NSObject: NSObject] = [kSecAttrIsPermanent: true as NSObject,
                                                        kSecAttrApplicationTag: bundleString as NSObject]
        
        let privateKeyAtrribute: [NSObject: NSObject] = [kSecAttrIsPermanent: true as NSObject,
                                                         kSecAttrApplicationTag: bundleString as NSObject]
        
        var keyPairAttr = [NSObject: Any]()
        keyPairAttr[kSecAttrType] = kSecAttrKeyTypeRSA
        keyPairAttr[kSecAttrKeySizeInBits] = 2048
        keyPairAttr[kSecReturnData] = true
        keyPairAttr[kSecPublicKeyAttrs] = publicKeyAttribute
        keyPairAttr[kSecPrivateKeyAttrs] = privateKeyAtrribute
        
        guard let priv = SecKeyCreateRandomKey(keyPairAttr as CFDictionary, nil),
              let publ = SecKeyCopyPublicKey(priv) else {
                  return nil
              }
        
        return Self.init(publicKey: publ, privateKey: priv)
    }
    
    public var privateKeyPEM: String? {
        let data = SecKeyCopyExternalRepresentation(privateKey, nil) as Data?
        let commonString = "RSA PRIVATE KEY"
        let prefix = "BEGIN \(commonString)".sorrounded(by: "-", times: 5) + "\n"
        let suffix = "\n" + "END \(commonString)".sorrounded(by: "-", times: 5)
        
        if let base64 = data?.base64EncodedString() {
            return prefix + base64 + suffix
        } else {
            return nil
        }
    }
    
    public var publicKeyPEM: String? {
        let data = SecKeyCopyExternalRepresentation(publicKey, nil) as Data?
        let commonString = "RSA PUBLIC KEY"
        let prefix = "BEGIN \(commonString)".sorrounded(by: "-", times: 5) + "\n"
        let suffix = "\n" + "END \(commonString)".sorrounded(by: "-", times: 5)
        
        if let base64 = data?.base64EncodedString() {
            return prefix + base64 + suffix
        } else {
            return nil
        }
    }
}

extension String {
    
    func sorrounded(by character: String, times: Int) -> String {
        let sorround = Array(repeating: character, count: times).joined(separator: "")
        return sorround + self + sorround
    }
    
}
