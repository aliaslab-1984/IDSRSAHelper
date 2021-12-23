import XCTest
@testable import IDSCertificateHelper

final class IDSCertificateHelperTests: XCTestCase {
    
    func testEncryption() throws {
      
        let string = "Ciao"
        let password = "password"
        guard let certificateUrl = Bundle.main.url(forResource: "CertificatoAutofirmato", withExtension: ".p12"),
              let certificateData = try? Data(contentsOf: certificateUrl) else {
            XCTFail("Empty certificate.")
                  return
        }
        
        if let certificate = RSA.extractCert(from: certificateData, password: password) {
            let encrypted = try XCTUnwrap(RSA.encrypt(string: string, with: certificate))
            let decrypted = try XCTUnwrap(RSA.decrypt(string: encrypted, with: certificate))
            
            XCTAssert(string == decrypted)
        }
    }
    
    func testGeneratedKeysEncription() throws {
      
        let string = "Ciao"
        
        let touple = RSA.encrypt(string: string)
        let encryptedString = try XCTUnwrap(touple.1)
        let keyPair = try XCTUnwrap(touple.0)
        let decrypted = try XCTUnwrap(RSA.decrypt(string: encryptedString, with: keyPair))
        
        XCTAssert(string == decrypted.1)
    }
    
    static var allTests = [
        ("testGeneratedKeysEncription", testGeneratedKeysEncription),
        ("testEncryption", testEncryption)
    ]
}
