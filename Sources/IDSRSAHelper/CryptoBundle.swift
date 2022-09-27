//
//  CryptoBundle.swift
//  
//
//  Created by Francesco Bianco on 20/01/22.
//

import Foundation
import Security

public struct CryptoBundle {
    var certificate: SecCertificate
    var identity: SecIdentity
    
    /// Given a p12 certificate and the corresponding password, it tries initialize the CryptoBundle instance.
    /// - p12Data: The data that represents the certificate.
    /// - password: The password to unlock the certificate.
    public init?(from p12Data: Data, password: String) {
        var items: CFArray?
        let certOptions: CFDictionary = [kSecImportExportPassphrase as String: password] as CFDictionary
        
        // import certificate to read its entries
        let securityError = SecPKCS12Import(p12Data as CFData, certOptions, &items)
        
        guard let certItems = items, securityError == errSecSuccess else {
            if securityError == errSecAuthFailed {
                print("Failed to authenticate the PKCS12 import. Wrong password ?")
            } else {
                print("Failed PKCS12 import. Other error: \(securityError)")
            }
            return nil
        }
        
        let certItemsArray: Array = certItems as Array
        let dict: AnyObject? = certItemsArray.first
        
        guard let certEntry: Dictionary = dict as? [String: AnyObject] else {
            print("No certificates found.")
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
        self.certificate = cert
        self.identity = secIdentity
    }
}
