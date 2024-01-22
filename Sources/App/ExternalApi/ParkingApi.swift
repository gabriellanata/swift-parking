import Vapor

actor ParkingApi {
    public static let shared = ParkingApi()

    func initialize() async throws {
        try await self.loadUsers()
    }

    private let sharedHeaders: HTTPHeaders = [
        "Accept":"application/json, text/plain, */*",
        "Accept-Language":"en-US,en;q=0.9",
        "Connection":"keep-alive",
        "Content-Type":"application/json",
        "Dnt":"1",
        "Origin":"https://m2.paybyphone.com",
        "Referer":"https://m2.paybyphone.com/",
        "Sec-Fetch-Dest":"empty",
        "Sec-Fetch-Mode":"cors",
        "Sec-Fetch-Site":"cross-site",
        "User-Agent":"Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36",
        "X-Pbp-Clienttype":"WebApp",
        "X-Pbp-Distributionchannel":"pbp-webapp",
        "Sec-Ch-Ua":"\"Not:A-Brand\";v=\"99\", \"Chromium\";v=\"112\"",
        "Sec-Ch-Ua-Mobile":"?1",
        "Sec-Ch-Ua-Platform":"\"Android\"",
        "X-Pbp-Version":"2",
        "X-Api-Key":"zZ4ePLvoBBD1YwBGCo6P5DiPLDjSss3j",
        "Accept-Encoding":"gzip",
    ]

    var users: [User] = []

    /// [username: Auth]
    var cachedAuths: [String: Auth] = [:]

    /// [username: AccountNumber]
    var cachedAccountNumbers: [String: String] = [:]

    /// [username: [PaymentCard]]
    var cachedPaymentCards: [String: [PaymentCard]] = [:]

    func vehicle(forLicensePlate licensePlate: String) -> Vehicle? {
        return self.users.compactMap { $0.vehicles.first { $0.licensePlate == licensePlate } }.first
    }

    func users(forVehicle vehicle: Vehicle) -> [User] {
        return self.users.filter { $0.vehicles.contains { $0 == vehicle } }
    }

    func activeAuth(forUser user: User) -> Auth? {
        if let auth = self.cachedAuths[user.username], auth.expirationDate > Date() {
            return auth
        } else {
            self.cachedAuths[user.username] = nil
            return nil
        }
    }

    @discardableResult
    func send(
        method: HTTPMethod,
        url: URI,
        auth: Auth?,
        headers: HTTPHeaders = [:],
        query: URLQuery = [:],
        body: any Content
    )
        async throws -> ClientResponse
    {
        var headers = self.sharedHeaders.replacingOrAdding(contentsOf: headers)
        if let auth = auth {
            headers.replaceOrAdd(name: "Authorization", value: auth.authHeader)
        }

        return try await Api.shared.send(method: method, url: url, headers: headers, query: query, body: body)
    }
}

