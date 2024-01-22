import Vapor

extension ParkingApi {
    func getPaymentCards(user: User) async throws -> [PaymentCard] {
        let auth = try await self.login(user: user)

        if let paymentCards = self.cachedPaymentCards[user.username] {
            return paymentCards
        }

        let response = try await self.send(
            method: .GET,
            url: "https://payments.paybyphoneapis.com/v1/accounts",
            auth: auth,
            body: PaymentCardsRequest()
        ).as(PaymentCardsResponse.self)

        self.cachedPaymentCards[user.username] = response.paymentCards
        return response.paymentCards
    }
}

private struct PaymentCardsRequest: Content {}

private struct PaymentCardsResponse: Content {
    let paymentCards: [PaymentCard]
}

