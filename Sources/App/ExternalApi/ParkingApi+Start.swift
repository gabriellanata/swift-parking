import Vapor

extension ParkingApi {
    func startSession(licensePlate: String, locationId: String, duration: Duration) async throws {
        guard let vehicle = self.vehicle(forLicensePlate: licensePlate) else {
            throw Abort(.custom(code: 601, reasonPhrase: "Vehicle not found for: \(licensePlate)"))
        }

        guard let user = self.users(forVehicle: vehicle).first else {
            throw Abort(.custom(code: 602, reasonPhrase: "User not found for: \(licensePlate)"))
        }

        let location = Location(name: "300 Block Park", locationId: locationId)

        guard let paymentCard = try await self.getPaymentCards(user: user).first else {
            throw Abort(.custom(code: 603, reasonPhrase: "No payment cards found for: \(user.username)"))
        }

        let quote = try await self.getQuote(user: user, vehicle: vehicle, location: location, duration: duration)

        try await self.createSession(user: user, quote: quote, paymentCard: paymentCard, duration: duration)
    }

    func stopSession(licensePlate: String) async throws {
        guard let vehicle = self.vehicle(forLicensePlate: licensePlate) else {
            throw Abort(.custom(code: 601, reasonPhrase: "Vehicle not found for: \(licensePlate)"))
        }

        guard let user = self.users(forVehicle: vehicle).first else {
            throw Abort(.custom(code: 602, reasonPhrase: "User not found for: \(licensePlate)"))
        }

        let location = Location(name: "300 Block Park", locationId: locationId)

        guard let paymentCard = try await self.getPaymentCards(user: user).first else {
            throw Abort(.custom(code: 603, reasonPhrase: "No payment cards found for: \(user.username)"))
        }

        let quote = try await self.getQuote(user: user, vehicle: vehicle, location: location, duration: duration)

        try await self.createSession(user: user, quote: quote, paymentCard: paymentCard, duration: duration)
    }
}

// 300s block: 37303004
