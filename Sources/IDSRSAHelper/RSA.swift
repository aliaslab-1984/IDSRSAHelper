//
//  Crypto.swift
//  IDSignQRGenerator
//
//  Created by Francesco Bianco on 22/12/21.
//

import Foundation
import Security

public struct RSA {
    
    public static var preferredAlgorithm: SecKeyAlgorithm = .rsaEncryptionPKCS1
    public static var bundle: String = {
        return Bundle.main.bundleIdentifier ?? "com.certificatehelper"
    }()
    
    public struct CryptoBundle {
        var certificate: SecCertificate
        var identity: SecIdentity
    }
    
    public enum CertificateKey: Int, Hashable {
        case privateKey = 0
        case publicKey = 1
    }
    
    enum CryptoAction {
        case encrypt
        case decrypt
        
        var keyToUse: CertificateKey {
            switch self {
            case .encrypt:
                return .publicKey
            case .decrypt:
                return .privateKey
            }
        }
    }
    
    // MARK: - API
    
    public static func decrypt(data: Data,
                               preferredKey: CertificateKey = .privateKey,
                               with bundle: CryptoBundle) -> String? {
        return manage(data, for: .decrypt, preferredKey: preferredKey, using: bundle)
    }
    
    
    public static func encrypt(data: Data,
                               preferredKey: CertificateKey = .publicKey,
                               with bundle: CryptoBundle) -> String? {
        return manage(data, for: .encrypt, preferredKey: preferredKey, using: bundle)
    }
    
    public static func decrypt(data: Data,
                               preferredKey: CertificateKey = .privateKey,
                               with pair: KeyPair) -> (KeyPair?, String?) {
        return manage(data, pair: pair, preferredKey: preferredKey, for: .decrypt)
    }
    
    public static func encrypt(data: Data,
                               preferredKey: CertificateKey = .publicKey) -> (KeyPair?, String?) {
        return manage(data, preferredKey: preferredKey, for: .encrypt)
    }
    
    public static func decrypt(string: String,
                               preferredKey: CertificateKey = .privateKey,
                               with bundle: CryptoBundle) -> String? {
        guard let data = Data(base64Encoded: string) else {
            return nil
        }
        return manage(data, for: .decrypt, preferredKey: preferredKey, using: bundle)
    }
    
    
    public static func encrypt(string: String,
                               preferredKey: CertificateKey = .publicKey,
                               with bundle: CryptoBundle) -> String? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        return manage(data, for: .encrypt, preferredKey: preferredKey, using: bundle)
    }
    
    public static func decrypt(string: String,
                               preferredKey: CertificateKey = .privateKey,
                               with pair: KeyPair) -> (KeyPair?, String?) {
        guard let data = Data(base64Encoded: string) else {
            return (nil, nil)
        }
        return manage(data, pair: pair, preferredKey: preferredKey, for: .decrypt)
    }
    
    public static func encrypt(string: String,
                               preferredKey: CertificateKey = .publicKey) -> (KeyPair?, String?) {
        guard let data = string.data(using: .utf8) else {
            return (nil, nil)
        }
        return manage(data, preferredKey: preferredKey, for: .encrypt)
    }
    
}

// MARK: -Actual decryption
private extension RSA {
    
    static func manage(_ value: Data,
                       pair: KeyPair? = nil,
                       preferredKey: CertificateKey,
                       for cryptoAction: CryptoAction) -> (KeyPair?, String?) {
        
        if cryptoAction == .encrypt {
            if let pair = pair {
                return (pair, newEncrypt(value, encryptionKey: pair.publicKey))
            } else if let newPair = KeyPair.newPair(for: bundle) {
                return (newPair, newEncrypt(value, encryptionKey: newPair.publicKey))
            } else {
                return (nil, nil)
            }
        } else {
            if let pair = pair {
                return (pair, newDecrypt(value, decryptionKey: pair.privateKey))
            } else if let newPair = KeyPair.newPair(for: bundle) {
                return (newPair, newDecrypt(value, decryptionKey: newPair.privateKey))
            } else {
                return (nil, nil)
            }
        }
    }
    
    static func manage(_ value: Data,
                       for cryptoAction: CryptoAction,
                       preferredKey: CertificateKey,
                       using bundle: CryptoBundle) -> String? {
        var trust: SecTrust?

        // Retrieve a SecTrust using the SecCertificate object. Provide X509 as policy
        let status = SecTrustCreateWithCertificates(bundle.certificate, SecPolicyCreateBasicX509(), &trust)

        // Check if the trust generation is success
        guard status == errSecSuccess else { return nil }

        let key: SecKey
        switch preferredKey {
        case .privateKey:
            var privateKey: SecKey?
            SecIdentityCopyPrivateKey(bundle.identity, &privateKey)
            guard let secKey = privateKey else { return nil }
            key = secKey
        case .publicKey:
            // Retrieve the SecKey using the trust hence generated
            if #available(iOS 14.0, *) {
                guard let secKey = SecTrustCopyKey(trust!) else { return nil }
                key = secKey
            } else {
                guard let secKey = SecTrustCopyPublicKey(trust!) else { return nil }
                key = secKey
            }
        }
      
        if cryptoAction == .encrypt {
            return newEncrypt(value, encryptionKey: key)
        } else {
            return newDecrypt(value, decryptionKey: key)
        }
    }
    
    static func newEncrypt(_ value: Data, encryptionKey: SecKey) -> String? {
        let coreFData = value as CFData
        let encrypt = SecKeyCreateEncryptedData(encryptionKey, preferredAlgorithm, coreFData, nil) as Data?

        return encrypt?.base64EncodedString()
    }
    
    static func newDecrypt(_ data: Data, decryptionKey: SecKey) -> String? {
        let coreFData = data as CFData
        
        guard let decrypt = SecKeyCreateDecryptedData(decryptionKey, preferredAlgorithm, coreFData, nil) as Data? else {
            return nil
        }
        return String(data: decrypt, encoding: .utf8)
    }
}

// MARK: - Utils
extension RSA {
    
    public static func extractCert(from p12Data: Data, password: String) -> CryptoBundle? {
        var items: CFArray?
        let certOptions: CFDictionary = [kSecImportExportPassphrase as String: password] as CFDictionary
        
        // import certificate to read its entries
        let securityError = SecPKCS12Import(p12Data as CFData, certOptions, &items)
        
        guard let certItems = items, securityError == errSecSuccess else {
            return nil
        }
        
        let certItemsArray: Array = certItems as Array
        let dict: AnyObject? = certItemsArray.first
        
        guard let certEntry: Dictionary = dict as? [String: AnyObject] else {
            return nil
        }
        
        // grab the identity
        guard let secIdentity = SecIdentity.conditionallyCast(certEntry["identity"]) else {
            return nil
        }
        
        // grab the certificate chain
        var certRef: SecCertificate?
        SecIdentityCopyCertificate(secIdentity, &certRef)
        guard let cert = certRef else {
            return nil
        }
        return CryptoBundle(certificate: cert, identity: secIdentity)
    }
}
