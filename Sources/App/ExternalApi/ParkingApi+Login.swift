import Vapor

extension ParkingApi {
    @discardableResult
    public func login(user: User) async throws -> Auth {
        if let auth = self.activeAuth(forUser: user) {
            return auth
        }

        print(try user.password.decrypted())

        let token = try await self.send(
            method: .POST,
            url: "https://auth.paybyphoneapis.com/token",
            auth: nil,
            headers: ["Content-Type": "application/x-www-form-urlencoded"],
            body: LoginRequest(
                grantType: "password",
                clientId: "paybyphone_web",
                username: user.username,
                password: user.password.decrypted()
            )
        ).as(LoginResponse.self)

        let auth = Auth(
            tokenType: token.tokenType,
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
            duration: token.expiresIn
        )

        self.cachedAuths[user.username] = auth
        return auth
    }
}

private struct LoginRequest: Content {
    let grantType: String
    let clientId: String
    let username: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case clientId = "client_id"
        case username = "username"
        case password = "password"
    }
}

private struct LoginResponse: Content {
    let tokenType: String
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case tokenType = "token_type"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}
