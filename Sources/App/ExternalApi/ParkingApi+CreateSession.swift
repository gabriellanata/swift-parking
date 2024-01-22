import Vapor

extension ParkingApi {
    func createSession(user: User, quote: Quote, paymentCard: PaymentCard, duration: Duration) async throws {
        let auth = try await self.login(user: user)

        try await self.send(
            method: .POST,
            url: "https://consumer.paybyphoneapis.com/parking/accounts/\(quote.parkingAccountId)/sessions/",
            auth: auth,
            body: CreateSessionRequest(
                parkingAccountId: quote.parkingAccountId,
                licensePlate: quote.licensePlate,
                rateOptionId: quote.locationId,
                duration: SessionDuration(quantity: "\(duration.minutes)", timeUnit: "Minutes"),
                locationId: quote.locationId,
                quoteId: quote.id,
                startTime: quote.parkingStartTime,
                expireTime: JSONNull(),
                paymentMethod: PaymentMethod(
                    paymentMethodType: "PaymentAccount",
                    payload: Payload(
                        paymentAccountId: paymentCard.id,
                        clientBrowserDetails: .default
                    )
                )
            )
        )
    }
}

private struct CreateSessionRequest: Content {
    let parkingAccountId: String
    let licensePlate: String
    let rateOptionId: String
    let duration: SessionDuration
    let locationId: String
    let quoteId: String
    let startTime: String
    let expireTime: JSONNull
    let paymentMethod: PaymentMethod
}

private struct SessionDuration: Codable {
    let quantity: String
    let timeUnit: String
}

private struct PaymentMethod: Codable {
    let paymentMethodType: String
    let payload: Payload
}

private struct Payload: Codable {
    let paymentAccountId: String
    let clientBrowserDetails: ClientBrowserDetails
}

private struct ClientBrowserDetails: Codable {
    let browserColorDepth: String
    let browserJavaEnabled: String
    let browserAcceptHeader: String
    let browserLanguage: String
    let browserScreenWidth: String
    let browserScreenHeight: String
    let browserTimeZone: String
    let browserUserAgent: String

    static let `default` = ClientBrowserDetails(
        browserColorDepth: "24",
        browserJavaEnabled: "true",
        browserAcceptHeader: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        browserLanguage: "en-US,en;q=0.5",
        browserScreenWidth: "1920",
        browserScreenHeight: "1080",
        browserTimeZone: "America/Los_Angeles",
        browserUserAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.16; rv:88.0) Gecko/20100101 Firefox/88.0"
    )
}

private struct CreateSessionResponse: Content {
}
