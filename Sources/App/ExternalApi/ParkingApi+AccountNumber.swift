import Vapor

extension ParkingApi {
    func getAccountNumber(user: User) async throws -> String {
        guard let auth = self.activeAuth(forUser: user) else {
            throw Abort(.unauthorized)
        }

        if let accountNumber = self.cachedAccountNumbers[user.username] {
            return accountNumber
        }

        let response = try await self.send(
            method: .GET,
            url: "https://consumer.paybyphoneapis.com/parking/accounts",
            auth: auth,
            body: AccountNumberRequest()
        ).as(AccountNumberResponse.self)

        guard let accountNumber = response.first?.id else {
            throw Abort(.notFound)
        }

        self.cachedAccountNumbers[user.username] = accountNumber
        return accountNumber
    }
}

private struct AccountNumberRequest: Content {
}

private typealias AccountNumberResponse = [AccountNumberResponseElement]
private struct AccountNumberResponseElement: Content {
    let id: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
    }
}
