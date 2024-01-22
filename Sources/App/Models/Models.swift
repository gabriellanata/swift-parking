import Foundation
import Vapor

struct User: Content, Equatable {
    let username: String
    let password: String
    let vehicles: [Vehicle]

    func asPrivate() -> User {
        return User(username: self.username, password: "****", vehicles: self.vehicles)
    }
}

struct Auth: Content, Equatable {
    let tokenType: String
    let accessToken: String
    let refreshToken: String
    let duration: TimeInterval
    let startDate: Date
    let expirationDate: Date

    var authHeader: String {
        return "\(self.tokenType) \(self.accessToken)"
    }

    init(tokenType: String, accessToken: String, refreshToken: String, duration: Int) {
        self.tokenType = tokenType
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.duration = TimeInterval(duration)
        self.startDate = Date()
        self.expirationDate = Date().addingTimeInterval(TimeInterval(duration))
    }
}

struct Vehicle: Content, Equatable {
    let id: String?
    let legacyId: String?
    let licensePlate: String
    let country: String?
    let jurisdiction: String?
    let type: String?

    init(id: String? = nil, legacyId: String? = nil, licensePlate: String,
         country: String? = nil, jurisdiction: String? = nil, type: String? = nil)
    {
        self.id = id
        self.legacyId = legacyId
        self.licensePlate = licensePlate
        self.country = country
        self.jurisdiction = jurisdiction
        self.type = type
    }

}

struct Location: Content, Equatable {
    let name: String
    let locationId: String
}

struct Quote: Content, Equatable {
    let id: String
    let locationId: String
    let quoteDate: String
    let cost: Decimal
    let parkingAccountId: String
    let parkingStartTime: String
    let parkingExpiryTime: String
    let licensePlate: String
}

struct PaymentCard: Content, Equatable {
    let id: String
    let maskedCardNumber: String
}

struct ParkingSession: Content, Equatable {
    let id: String
    let locationId: String
    let startTime: String
    let expireTime: String
    let isStoppable: Bool
    let isExtendable: Bool
    let isRenewable: Bool
    let maxStayState: String
    let licensePlate: String
}
