import Foundation
import NIOCore

extension Duration {
    static func minutes(_ minutes: Int64) -> Duration {
        return Duration(secondsComponent: minutes * 60, attosecondsComponent: 0)
    }

    var minutes: Int {
        return Int(round(Double(self.components.seconds) / 60.0))
    }
}

extension ByteBuffer {
    func asString() -> String {
        return String(buffer: self)
    }
}


final class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    func hash(into hasher: inout Hasher) {
        // Do nothing
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

extension String {
    func extractText(start startTag: String, end endTag: String) -> String? {
        return (range(of: startTag)?.upperBound).flatMap { substringFrom in
            (range(of: endTag, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

extension Sequence {
    func mapAsync<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()
        for element in self {
            try await values.append(transform(element))
        }

        return values
    }

    func flatMapAsync<T>(_ transform: (Element) async throws -> [T]) async rethrows -> [T] {
        return try await self.mapAsync(transform).flatMap { $0 }
    }
}

extension Duration {
    var seconds: TimeInterval {
        TimeInterval(self.components.seconds)
    }
}
