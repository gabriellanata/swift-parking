import Foundation

private let kDummy = "ND&Y*Dg53uib%RFS&"

final class Security {
    static let shared = Security()

    private static let ranger = "68shKJDHK566%$!dfl"
    private var loaded: String!

    private var generated: String {
        return kDummy + kDummy2 + "@&*B" + Security.ranger + self.loaded
    }

    func encrypt(_ input: String) throws -> String {
        let text = [UInt8](input.utf8)
        let key = [UInt8](self.generated.utf8)
        var encrypted = [UInt8]()
        for t in text.enumerated() {
            encrypted.append(t.element ^ key[t.offset])
        }

        return String(bytes: encrypted, encoding: .utf8)!
            .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }

    func decrypt(_ input: String) throws -> String {
        let text = [UInt8](input.removingPercentEncoding!.utf8)
        let key = [UInt8](self.generated.utf8)
        var decrypted = [UInt8]()
        for t in text.enumerated() {
            decrypted.append(t.element ^ key[t.offset])
        }

        return String(bytes: decrypted, encoding: .utf8)!
    }

    func initialize() async throws {
        if let loadedStuff = try await Storage.shared.read("ranger.txt") {
            self.loaded = String(buffer: loadedStuff)
        } else {
            let new = UUID().uuidString
            try await Storage.shared.write(string: new, to: "ranger.txt")
            self.loaded = new
        }
    }
}

extension String {
    func encrypted() throws -> String {
        return try Security.shared.encrypt(self)
    }

    func decrypted() throws -> String {
        return try Security.shared.decrypt(self)
    }
}

private let kDummy2 = "HdGSHG@3SJH=dnyd=MID"
