import Vapor

extension ParkingApi {
    func createSession(user: User, quote: Quote, paymentCard: PaymentCard, duration: Duration)
        async throws -> ParkingSession
    {
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

        return ParkingSession(
            id: nil,
            locationId: quote.locationId,
            startTime: quote.parkingStartTime,
            expireTime: quote.parkingExpiryTime,
            isExtendable: nil,
            licensePlate: quote.licensePlate,
            username: user.username
        )
    }

    func extendSession(user: User, quote: Quote, sessionId: String, paymentCard: PaymentCard, duration: Duration)
        async throws -> ParkingSession
    {
        let auth = try await self.login(user: user)

        try await self.send(
            method: .PUT,
            url: "https://consumer.paybyphoneapis.com/parking/accounts/\(quote.parkingAccountId)/sessions/\(sessionId)",
            auth: auth,
            body: ExtendSessionRequest(
                duration: SessionDuration(quantity: "\(duration.minutes)", timeUnit: "Minutes"),
                quoteId: quote.id,
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

        return ParkingSession(
            id: nil,
            locationId: quote.locationId,
            startTime: quote.parkingStartTime,
            expireTime: quote.parkingExpiryTime,
            isExtendable: nil,
            licensePlate: quote.licensePlate,
            username: user.username
        )
    }
}

private struct CreateSessionRequest: Content {
    let parkingAccountId: String
    let licensePlate: LicensePlate
    let rateOptionId: Location
    let duration: SessionDuration
    let locationId: Location
    let quoteId: String
    let startTime: String
    let expireTime: JSONNull
    let paymentMethod: PaymentMethod
}

private struct ExtendSessionRequest: Content {
    let duration: SessionDuration
    let quoteId: String
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
