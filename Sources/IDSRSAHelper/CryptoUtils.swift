//
//  CryptoUtils.swift
//  IDSignQRGenerator
//
//  Created by Francesco Bianco on 23/12/21.
//

import Foundation

extension String {
    
    var cfData: CFData? {
        let buffer = [UInt8](self.utf8)
        return CFDataCreate(nil, buffer, buffer.count)
    }
}

extension Data {
    
    var secCertificate: SecCertificate? {
        return SecCertificateCreateWithData(nil, self as NSData)
    }
}

protocol CFType {
    static var typeID: CFTypeID { get }
}

extension CFType {
    
    static func conditionallyCast(_ value: Any?) -> Self? {
        
        guard let value = value, CFGetTypeID(value as CFTypeRef) == typeID else {
            return nil
        }
        
        // swiftlint:disable:next force_cast
        return (value as! Self)
    }
}

extension SecCertificate: CFType {
    
    static var typeID: CFTypeID {
        return SecCertificateGetTypeID()
    }
}

extension SecIdentity: CFType {
    
    static var typeID: CFTypeID {
        return SecIdentityGetTypeID()
    }
}

extension SecTrust: CFType {
    
    static var typeID: CFTypeID {
        return SecTrustGetTypeID()
    }
}
