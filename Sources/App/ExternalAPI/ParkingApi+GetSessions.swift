import Vapor

extension ParkingApi {
    func getSessions(licensePlate: LicensePlate) async throws -> [ParkingSession] {
        guard let vehicle = self.vehicle(forLicensePlate: licensePlate) else {
            throw Abort(.custom(code: 601, reasonPhrase: "Vehicle not found for: \(licensePlate)"))
        }

        return try await self.users(forVehicle: vehicle)
            .flatMapAsync { try await self.getSessions(user: $0) }
            .filter { $0.licensePlate == licensePlate }
    }

    func getSessions(user: User) async throws -> [ParkingSession] {
        let auth = try await self.login(user: user)

        let accountNumber = try await self.getAccountNumber(user: user)

        let response = try await self.send(
            method: .GET,
            url: "https://consumer.paybyphoneapis.com/parking/accounts/\(accountNumber)/sessions",
            auth: auth,
            query: ["periodType": "Current"],
            body: GetSessionsRequest()
        ).as(GetSessionsResponse.self)

        return response.map {
            ParkingSession(
                id: $0.parkingSessionId,
                locationId: $0.locationId,
                startTime: $0.startTime,
                expireTime: $0.expireTime,
                //isStoppable: $0.isStoppable,
                isExtendable: $0.isExtendable,
                //isRenewable: $0.isRenewable,
                //maxStayState: $0.maxStayState,
                licensePlate: $0.vehicle.licensePlate,
                username: user.username
            )
        }
    }
}

private struct GetSessionsRequest: Content {}

private typealias GetSessionsResponse = [GetSessionsResponseElement]
private struct GetSessionsResponseElement: Content {
    struct SessionVehicle: Content {
        // let id: Int
        let licensePlate: LicensePlate
    }

    let parkingSessionId: String
    let locationId: Location
    let startTime: String
    let stall: String?
    let expireTime: String
    let vehicle: SessionVehicle
    let isStoppable: Bool
    let fpsApplies: Bool
    let isExtendable: Bool
    let isRenewable: Bool
    let maxStayState: String
}
