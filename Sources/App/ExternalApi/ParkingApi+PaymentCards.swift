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

        let paymentCards = response.paymentCards.map { paymentCard in
            PaymentCard(id: paymentCard.paymentAccountId, maskedCardNumber: paymentCard.maskedCardNumber)
        }

        self.cachedPaymentCards[user.username] = paymentCards
        return paymentCards
    }
}

private struct PaymentCardsRequest: Content {}

private struct PaymentCardsResponse: Content {
    struct PaymentCard: Content, Equatable {
        let paymentAccountId: String
        let maskedCardNumber: String
    }

    let paymentCards: [PaymentCard]
}
