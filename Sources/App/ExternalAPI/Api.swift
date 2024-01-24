import Vapor

actor Api {
    public static let shared = Api()

    func initialize(client: Client) async throws {
        self.client = client
    }

    private var client: Client!

    func send(
        method: HTTPMethod,
        url: URI,
        headers: HTTPHeaders = [:],
        query: (any Content)? = nil,
        body: (any Content)? = nil
    )
        async throws -> ClientResponse
    {
        
        let response = try await self.client.send(method, headers: headers, to: url) { req in
            if let query {
                try req.query.encode(query)
            }

            if let body {
                try req.content.encode(body, as: headers.contentType ?? .json)
            }
        }

        print("Request: \(method) \(url)")
        print(" - Response: \(response.status)")
        if response.status.code > 205 {
            print(" - Body: \(response.body?.asString() ?? "nil")")
        }

        return response
    }
}

extension ClientResponse {
    func `as`<C: Content>(_ responseType: C.Type) throws -> C {
        do {
            return try self.content.decode(C.self)
        } catch {
            var theError: Error = error
            if let parsedError = try? self.content.decode(ErrorResponse.self), !parsedError.isEmpty {
                theError = parsedError
            } else {
                print("Unhandled error: \(theError)")
                print(" - Content type: \(self.content.contentType?.description ?? "None")")
                print(" - Body: \(self.body?.asString() ?? "nil")")
            }

            print("Error from: \(theError)")
            throw theError
        }
    }
}

extension HTTPHeaders {
    func replacingOrAdding(contentsOf content: HTTPHeaders) -> HTTPHeaders {
        var copy = self
        for (key, value) in content {
            copy.replaceOrAdd(name: key, value: value)
        }

        return copy
    }
}

struct ErrorResponse: Error, Content {
    struct Issue: Content {
        let reason: String
    }

    let issues: [Issue]?
    let error: String?
    let errorDescription: String?

    var isEmpty: Bool {
        return self.issues == nil && self.error == nil && self.errorDescription == nil
    }

    enum CodingKeys: String, CodingKey {
        case error
        case issues
        case errorDescription = "error_description"
    }
}
