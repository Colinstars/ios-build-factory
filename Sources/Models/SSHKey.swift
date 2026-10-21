import Foundation
import CryptoKit

/// SSH 密钥数据模型 (支持 Ed25519、RSA 等工业级公私钥管理)
struct SSHKey: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var keyType: KeyType
    var privateKeyPEM: String
    var publicKeyOpenSSH: String
    var passphrase: String?
    let createdAt: Date

    enum KeyType: String, Codable, CaseIterable {
        case ed25519 = "Ed25519"
        case rsa = "RSA (4096-bit)"
    }

    init(id: UUID = UUID(),
         name: String,
         keyType: KeyType = .ed25519,
         privateKeyPEM: String,
         publicKeyOpenSSH: String = "",
         passphrase: String? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.keyType = keyType
        self.privateKeyPEM = privateKeyPEM
        self.publicKeyOpenSSH = publicKeyOpenSSH
        self.passphrase = passphrase
        self.createdAt = createdAt
    }

    /// 在本地快速生成全新的 Ed25519 密钥对
    static func generateEd25519(name: String) -> SSHKey {
        let privateKey = Curve25519.Signing.PrivateKey()
        let rawPriv = privateKey.rawRepresentation.base64EncodedString()
        let rawPub = privateKey.publicKey.rawRepresentation.base64EncodedString()
        let pubString = "ssh-ed25519 \(rawPub) \(name.lowercased().replacingOccurrences(of: " ", with: "-"))@serverlens"

        return SSHKey(
            name: name,
            keyType: .ed25519,
            privateKeyPEM: rawPriv,
            publicKeyOpenSSH: pubString
        )
    }
}
