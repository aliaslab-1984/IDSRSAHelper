//
//  File.swift
//  
//
//  Created by Francesco Bianco on 28/01/22.
//

import Foundation

/// Describes what SecCertificate SecKey should be used to ecnrypt/decrypt a piece of data.
public enum CryptographicKey: Int, Hashable {
    case privateKey = 0
    case publicKey = 1
}

/// Describes the cryptographical action that needs to be performed by the SDK.
public enum CryptoAction {
    case encrypt
    case decrypt
    
    var keyToUse: CryptographicKey {
        switch self {
        case .encrypt:
            return .publicKey
        case .decrypt:
            return .privateKey
        }
    }
}

public enum StringFormat: Int {
    case base64
    case plain
}
