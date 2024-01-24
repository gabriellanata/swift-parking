import Vapor

extension ParkingApi {
    func getQuote(
        user: User,
        vehicle: Vehicle, locationId: Location, duration: Duration
    ) async throws -> Quote
    {
        let auth = try await self.login(user: user)

        let accountNumber = try await self.getAccountNumber(user: user)

        let response = try await self.send(
            method: .GET,
            url: "https://consumer.paybyphoneapis.com/parking/accounts/\(accountNumber)/quote",
            auth: auth,
            query: [
                "locationId": "\(locationId)",
                "licensePlate": vehicle.licensePlate,
                "rateOptionId": "\(locationId)",
                "durationTimeUnit": "Minutes",
                "durationQuantity": "\(duration.minutes)",
                "isParkUntil": "false",
                // "expireTime": "null",
                "parkingAccountId": accountNumber,
            ],
            body: GetQuoteRequest()
        ).as(GetQuoteResponse.self)

        return Quote(
            id: response.quoteId,
            locationId: response.locationId,
            quoteDate: response.quoteDate,
            cost: response.totalCost.amount,
            parkingAccountId: response.parkingAccountId,
            parkingStartTime: response.parkingStartTime,
            parkingExpiryTime: response.parkingExpiryTime,
            licensePlate: response.licensePlate
        )
    }

    func getQuoteExtend(
        user: User, accountNumber: String,
        parkingSessionId: String, duration: Duration
    ) async throws -> Quote
    {
        guard let auth = self.activeAuth(forUser: user) else {
            throw Abort(.unauthorized)
        }

        let response = try await self.send(
            method: .GET,
            url: "https://consumer.paybyphoneapis.com/parking/accounts/\(accountNumber)/quote",
            auth: auth,
            query: [
                "parkingSessionId": parkingSessionId,
                "durationTimeUnit": "Minutes",
                "durationQuantity": "\(duration.minutes)",
                "isParkUntil": "false",
                // "expireTime": "null",
                "parkingAccountId": accountNumber,
            ],
            body: GetQuoteRequest()
        ).as(GetQuoteResponse.self)

        return Quote(
            id: response.quoteId,
            locationId: response.locationId,
            quoteDate: response.quoteDate,
            cost: response.totalCost.amount,
            parkingAccountId: response.parkingAccountId,
            parkingStartTime: response.parkingStartTime,
            parkingExpiryTime: response.parkingExpiryTime,
            licensePlate: response.licensePlate
        )
    }
}

private struct GetQuoteRequest: Content {
}

private struct GetQuoteResponse: Content {
    let locationId: Location
    let stall: String?
    let quoteDate: String
    let totalCost: Money
    let parkingAccountId: String
    let parkingStartTime: String
    let parkingExpiryTime: String
    let parkingDurationAdjustment: String
    let licensePlate: LicensePlate
    let quoteId: String
}

private struct Money: Content {
    let amount: Decimal
    let currency: String
}
