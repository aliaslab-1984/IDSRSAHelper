//
//  File.swift
//  
//
//  Created by Francesco Bianco on 25/07/22.
//

import Foundation
import openssl_grpc
import Security

public struct BoringCertificate {
    
    //https://stackoverflow.com/questions/8850524/seccertificateref-how-to-get-the-certificate-information/
    
    private let bundle: CryptoBundle
    
    init(bundle: CryptoBundle) {
        self.bundle = bundle
    }
    
    init?(certificateData: Data, passPhrase: String) {
        guard let bundle = CryptoBundle(from: certificateData, password: passPhrase) else {
            return nil
        }
        
        self.bundle = bundle
    }
    
    public func expiryDate(_ completion: @escaping (Date?) -> Void) {
        var certData = SecCertificateCopyData(bundle.certificate) as Data
        
        certData.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>?) -> Void in
            //Use `bytes` inside this closure
            var byte = bytes
            guard let certificate = d2i_X509(nil, &byte , certData.count) else {
                completion(nil)
                return
            }
            completion(Self.getExpiryDate(certificateX509: certificate))
        })
    }
}

private extension BoringCertificate {
    
    static func getExpiryDate(certificateX509: OpaquePointer) -> Date? {
        
        guard let certificateExpiryASN1 = X509_get_notAfter(certificateX509) else {
            return nil
        }
        guard let certificateExpiryASN1Generalized = ASN1_TIME_to_generalizedtime(certificateExpiryASN1, nil) else {
            return nil
        }
        
        guard let certificateExpiryData = ASN1_STRING_data(certificateExpiryASN1Generalized) else { return nil }
        
        // ASN1 generalized times look like this: "20131114230046Z"
        //                                format:  YYYYMMDDHHMMSS
        //                               indices:  01234567890123
        //                                                   1111
        // There are other formats (e.g. specifying partial seconds or
        // time zones) but this is good enough for our purposes since
        // we only use the date and not the time.
        //
        // (Source: http://www.obj-sys.com/asn1tutorial/node14.html)
        
        guard let expiryTimeStr = NSString(utf8String: certificateExpiryData) else {
            return nil
        }
        var expiryDateComponents = DateComponents()
        
        
        expiryDateComponents.year   = expiryTimeStr.substring(with: NSMakeRange(0, 4)).intValue ?? 0
        expiryDateComponents.month  = expiryTimeStr.substring(with: NSMakeRange(4, 2)).intValue ?? 0
        expiryDateComponents.day    = expiryTimeStr.substring(with: NSMakeRange(6, 2)).intValue ?? 0
        expiryDateComponents.hour   = expiryTimeStr.substring(with: NSMakeRange(8, 2)).intValue ?? 0
        expiryDateComponents.minute = expiryTimeStr.substring(with: NSMakeRange(10, 2)).intValue ?? 0
        expiryDateComponents.second = expiryTimeStr.substring(with: NSMakeRange(12, 2)).intValue ?? 0
        
        let calendar = Calendar.current
        return calendar.date(from: expiryDateComponents)
    }
    
}

extension String {
    
    var intValue: Int? {
        return Int(self)
    }
    
}
