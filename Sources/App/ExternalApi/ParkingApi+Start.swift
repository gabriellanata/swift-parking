import Vapor

extension ParkingApi {
    func startSession(licensePlate: LicensePlate, locationId: Location, duration: Duration)
        async throws -> ParkingSession
    {
        let existingSessions = try await self.getSessions(licensePlate: licensePlate)

        var sessionExtension: (sessionId: String, duration: Duration)? = nil
        if let existingSession = existingSessions.first(where: { $0.locationId == locationId }) {
            let durationExtensionSeconds = Int(duration.seconds - existingSession.remainingTime())
            if durationExtensionSeconds > 0 {
                sessionExtension = (
                    sessionId: existingSession.id!,
                    duration: .seconds(durationExtensionSeconds)
                )
            } else {
                return existingSession
            }
        }

        guard let vehicle = self.vehicle(forLicensePlate: licensePlate) else {
            throw Abort(.custom(code: 601, reasonPhrase: "Vehicle not found for: \(licensePlate)"))
        }

        guard let user = self.users(forVehicle: vehicle).first else {
            throw Abort(.custom(code: 602, reasonPhrase: "User not found for: \(licensePlate)"))
        }

        guard let paymentCard = try await self.getPaymentCards(user: user).first else {
            throw Abort(.custom(code: 603, reasonPhrase: "No payment cards found for: \(user.username)"))
        }

        if let sessionExtension {
            print("Extending session: \(sessionExtension.sessionId) by \(sessionExtension.duration) seconds")

            let quote = try await self.getQuoteExtend(
                user: user,
                sessionId: sessionExtension.sessionId,
                duration: sessionExtension.duration
            )

            return try await self.extendSession(
                user: user,
                quote: quote,
                sessionId: sessionExtension.sessionId,
                paymentCard: paymentCard,
                duration: sessionExtension.duration
            )

        } else {
            print("Starting session: \(licensePlate) at \(locationId) for \(duration) minutes")

            let quote = try await self.getQuote(
                user: user,
                vehicle: vehicle,
                locationId: locationId,
                duration: duration
            )

            return try await self.createSession(
                user: user, 
                quote: quote,
                paymentCard: paymentCard, 
                duration: duration
            )
        }
    }

    func startAutomatedSession(
        licensePlate: LicensePlate,
        locationId: Location,
        duration: Duration
    )
        async throws -> AutomatedParkingSession
    {
        let session = try await self.startSession(licensePlate: licensePlate, locationId: locationId, duration: duration)

        let automatedSession = AutomatedParkingSession(
            locationId: session.locationId,
            startDate: session.startDate,
            expireDate: session.expireDate,
            licensePlate: session.licensePlate,
            username: session.username
        )

        self.activeAutomatedSessions.append(automatedSession)

        return automatedSession
    }

    func extendAutomatedSessions() async throws {
        for automatedSession in self.activeAutomatedSessions {
            let licensePlate = automatedSession.licensePlate
            let remainingFullDuration = automatedSession.remainingTime()
            guard remainingFullDuration > 0 else {
                try await self.stopAutomatedSession(licensePlate: licensePlate)
                continue
            }

            let existingSessions = try await self.getSessions(licensePlate: licensePlate)


            let session = try await self.startSession(
                licensePlate: automatedSession.licensePlate,
                locationId: automatedSession.locationId,
                duration: .seconds(Int(remainingFullDuration))
            )

            automatedSession.startDate = session.startDate
            automatedSession.expireDate = session.expireDate
        }
    }

    func stopAutomatedSession(licensePlate: LicensePlate) async throws {
        self.activeAutomatedSessions.removeAll(where: { $0.licensePlate == licensePlate })
    }
}
