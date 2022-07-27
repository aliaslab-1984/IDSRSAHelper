//
//  File.swift
//  
//
//  Created by Francesco Bianco on 25/07/22.
//

import Foundation
import XCTest
@testable import IDSRSAHelper

let base64 = "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"

let standardCertificateb64 = "MIIDzTCCArWgAwIBAgIJAOpM7W2HTVJ/MA0GCSqGSIb3DQEBCwUAMH0xCzAJBgNVBAYTAklUMTEwLwYDVQQKDChUZWxlY29tIEl0YWxpYSBUcnVzdCBUZWNobm9sb2dpZXMgUy5yLmwuMSAwHgYDVQQLDBdTZXJ2aXppIGRpIEtleSBSZWNvdmVyeTEZMBcGA1UEAwwQVGVhbSBTeXN0ZW0gMjAxNzAeFw0xNzExMjgxODQ4MzNaFw00NzExMjkxODQ4MzNaMH0xCzAJBgNVBAYTAklUMTEwLwYDVQQKDChUZWxlY29tIEl0YWxpYSBUcnVzdCBUZWNobm9sb2dpZXMgUy5yLmwuMSAwHgYDVQQLDBdTZXJ2aXppIGRpIEtleSBSZWNvdmVyeTEZMBcGA1UEAwwQVGVhbSBTeXN0ZW0gMjAxNzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMWg+ElIgGGb9I5/F4dSbonZDMxuX7i9GL0fE0ged9xBVMUmWOIER5XiqmHSD5qGGFVpUAdAwkclLIXlqGF9e83BRzhxO1WY30s8YW9WfVKjKHZ2xfugrcjZPOsayi7QC/H9vP18vCXrV5kCD9adjIInYSPrUy01BeO//x9+lCxG8iA28ejj2VJqMmsbyVzWOfaV9CLtfwR/R05mUAXyO8eN3imPdpcVzkY7LgxXsTOdWpv29fTVOXbIevqq2pOtdVfJPHW23fnpgMH/INwqXxynje2ZY3Ld8qa45yvH+RmB0Zaq6QogPGCOvgJI0M/iTefSYz2t1+rn09YIEdWF5FECAwEAAaNQME4wHQYDVR0OBBYEFDOAYZCQDZkvpwOYE89suNhCcgX4MB8GA1UdIwQYMBaAFDOAYZCQDZkvpwOYE89suNhCcgX4MAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBADNMGM2dYcxptRAnzlIUNVGlBEPPCwmoDXVKy2PxSboJ7IpFihQgpy1BSkOMjM12BlZJUL7Bs/+ZbOb3lYpSGQuPYHPwTZDkll8tBj0hEZy5nRzaHLsEpNaYwsgZUnWxjDKTRoEnu3sZyXFezIt94L/Vj+6hQ088FGb5Vhf1twVskckq/Iog12b8iEIioXuwWXs/oIPsW7tKLt8++DtRk4tpEU56Xw+YJ7h2rNwpbIYySittKwUnSbwPw1H/1OnXQvYg0OOSdHLjq/TsPfXwRidoFgf1cZ2f/mbtO42ia3tqwFiSkIlMO5CLB1/74KwQvXKJo6VYFlv/mSDrCSxgARY="

final class CertificateValidityTest: XCTestCase {
    
    func testValidity() throws {
        
        guard let stringData = base64.data(using: .utf8) else {
            XCTFail("Cannot convert in data.")
            return
        }
        
        guard let data = Data(base64Encoded: stringData) else {
            XCTFail("Cannot open.")
            return
        }
        
        let expectation = expectation(description: "Date")
        
        guard let bCertificate = BoringCertificate(certificateData: data, passPhrase: ")?=*Hehy56&%2Ax+") else {
            XCTFail("Cannot instantiate bundle.")
            return
        }
        
        bCertificate.expiryDate { resultDate in
            XCTAssertNotNil(resultDate)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testValidityCert() throws {
        
        guard let stringData = standardCertificateb64.data(using: .utf8) else {
            XCTFail("Cannot convert in data.")
            return
        }
        
        guard let data = Data(base64Encoded: stringData) else {
            XCTFail("Cannot open.")
            return
        }
        
        let expectation = expectation(description: "Date")
        
        let certificate = try XCTUnwrap(data.secCertificate)
        
        certificate.expiryDate { resultDate in
            print(resultDate)
            XCTAssertNotNil(resultDate)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
}
