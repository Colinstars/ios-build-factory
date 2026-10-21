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

    /// 核心解析器：支持 32 字节 Raw Base64、64 字节密钥对，以及 OpenSSH 标准 PEM 格式 (-----BEGIN OPENSSH PRIVATE KEY-----)
    func parseEd25519PrivateKey() -> Curve25519.Signing.PrivateKey? {
        let cleanText = privateKeyPEM
            .replacingOccurrences(of: "-----BEGIN OPENSSH PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END OPENSSH PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()

        guard let rawBytes = Data(base64Encoded: cleanText) else { return nil }

        // 情况 1: 纯 32 字节原始 Seed
        if rawBytes.count == 32 {
            return try? Curve25519.Signing.PrivateKey(rawRepresentation: rawBytes)
        }

        // 情况 2: 64 字节 (32 字节私钥 + 32 字节公钥)
        if rawBytes.count == 64 {
            let seed = rawBytes.prefix(32)
            return try? Curve25519.Signing.PrivateKey(rawRepresentation: seed)
        }

        // 情况 3: OpenSSH v1 格式解包
        if rawBytes.starts(with: [0x6f, 0x70, 0x65, 0x6e, 0x73, 0x73, 0x68, 0x2d, 0x6b, 0x65, 0x79, 0x2d, 0x76, 0x31, 0x00]) {
            var offset = 15 // 越过 "openssh-key-v1\0"

            func readField() -> Data? {
                guard offset + 4 <= rawBytes.count else { return nil }
                let length = Int(rawBytes[offset]) << 24 | Int(rawBytes[offset+1]) << 16 | Int(rawBytes[offset+2]) << 8 | Int(rawBytes[offset+3])
                offset += 4
                guard offset + length <= rawBytes.count else { return nil }
                let sub = rawBytes.subdata(in: offset..<(offset + length))
                offset += length
                return sub
            }

            _ = readField() // ciphername ("none")
            _ = readField() // kdfname ("none")
            _ = readField() // kdfoptions
            guard offset + 4 <= rawBytes.count else { return nil }
            let numKeys = Int(rawBytes[offset]) << 24 | Int(rawBytes[offset+1]) << 16 | Int(rawBytes[offset+2]) << 8 | Int(rawBytes[offset+3])
            offset += 4
            guard numKeys > 0 else { return nil }
            _ = readField() // pubkey block
            guard let privBlock = readField() else { return nil }

            // 解析未加密的私钥块
            var pOffset = 8 // 跳过 2 个 32-bit checkint
            func readPrivSub() -> Data? {
                guard pOffset + 4 <= privBlock.count else { return nil }
                let length = Int(privBlock[pOffset]) << 24 | Int(privBlock[pOffset+1]) << 16 | Int(privBlock[pOffset+2]) << 8 | Int(privBlock[pOffset+3])
                pOffset += 4
                guard pOffset + length <= privBlock.count else { return nil }
                let sub = privBlock.subdata(in: pOffset..<(pOffset + length))
                pOffset += length
                return sub
            }

            _ = readPrivSub() // keytype ("ssh-ed25519")
            _ = readPrivSub() // pubkey bytes (32 bytes)
            if let privBytes = readPrivSub() {
                // ed25519 的 privBytes 是 64 字节 (32 字节私钥 seed + 32 字节公钥)
                let seed = privBytes.prefix(32)
                return try? Curve25519.Signing.PrivateKey(rawRepresentation: seed)
            }
        }

        return nil
    }
}
