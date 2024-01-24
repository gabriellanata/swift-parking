import Vapor

func routes(_ app: Application) {
    app.group("session") { route in
        route.get { req async throws in
            struct RequestBody: Content {
                let licensePlate: LicensePlate
            }

            let requestBody = try req.content.decode(RequestBody.self)
            return try await ParkingApi.shared.getSessions(licensePlate: requestBody.licensePlate)
        }

        route.post("start") { req async throws in
            struct RequestBody: Content {
                let licensePlate: LicensePlate
                let location: Location
                let minutes: Int
            }

            let requestBody = try req.content.decode(RequestBody.self)
            let duration = Duration.minutes(Int64(requestBody.minutes))
            return try await ParkingApi.shared.startSession(licensePlate: requestBody.licensePlate,
                                                            locationId: requestBody.location,
                                                            duration: duration)
        }

        route.post("end") { req async throws in
            struct RequestBody: Content {
                let licensePlate: LicensePlate
            }

            let requestBody = try req.content.decode(RequestBody.self)
            try await ParkingApi.shared.stopSession(licensePlate: requestBody.licensePlate)
            return Response(status: .ok)
        }
    }

    app.group("users") { route in
        route.get { req async throws in
            return await ParkingApi.shared.users.map { $0.asPrivate() }
        }

        route.post("add") { req async throws in
            struct RequestBody: Content {
                let username: String
                let password: String
                let licensePlate: LicensePlate
            }

            let requestBody = try req.content.decode(RequestBody.self)
            let response = try await ParkingApi.shared.addUser(username: requestBody.username,
                                                               password: requestBody.password,
                                                               licensePlate: requestBody.licensePlate)

            return Response(status: .accepted, body: .init(string: response))
        }

        route.post("remove") { req async throws in
            struct RequestBody: Content {
                let username: String?
                let licensePlate: LicensePlate?
            }

            let requestBody = try req.content.decode(RequestBody.self)

            if let username = requestBody.username {
                let response = try await ParkingApi.shared.removeUser(username: username)
                return Response(status: .accepted, body: .init(string: response))
            }

            if let licensePlate = requestBody.licensePlate {
                let response = try await ParkingApi.shared.removeUsers(licensePlate: licensePlate)
                return Response(status: .accepted, body: .init(string: response))
            }

            throw Abort(.badRequest)
        }
    }

    app.get("tickets") { req async throws in
        guard let licensePlate = req.query[String.self, at: "licensePlate"] else {
            throw Abort(.badRequest)
        }

        let filter = req.query[Ticket.Filter.self, at: "filter"] ?? .unpaid
        return try await TicketApi.shared.checkForTickets(licensePlate: licensePlate, filter: filter)
    }

    app.get("tick") { req async throws in
        return Response(status: .ok)
    }
}
