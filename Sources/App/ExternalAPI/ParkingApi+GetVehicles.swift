//import Vapor
//
//extension ParkingApi {
//    func getVehicles(user: User) async throws -> [Vehicle] {
//        let auth = try await self.login(user: user)
//
//        let response = try await self.send(
//            method: .GET,
//            url: "https://consumer.paybyphoneapis.com/identity/profileservice/v1/members/vehicles/paybyphone",
//            auth: auth,
//            body: GetVehiclesRequest()
//        ).as(GetVehiclesResponse.self)
//
//        return response.map {
//            Vehicle(
//                id: $0.vehicleId,
//                legacyId: $0.legacyVehicleId,
//                licensePlate: $0.licensePlate,
//                country: $0.country,
//                jurisdiction: $0.jurisdiction,
//                type: $0.type
//            )
//        }
//    }
//}
//
//private struct GetVehiclesRequest: Content {}
//
//private typealias GetVehiclesResponse = [GetVehiclesResponseElement]
//private struct GetVehiclesResponseElement: Content {
//    let vehicleId: String
//    let legacyVehicleId: String
//    let licensePlate: String
//    let country: String
//    let jurisdiction: String
//    let type: String
//}
