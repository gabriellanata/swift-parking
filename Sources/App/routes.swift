import Vapor

func routes(_ app: Application) {
    app.group("session") { route in
        route.get { req async throws in
            guard let licensePlate = req.query[String.self, at: "licensePlate"] else {
                throw Abort(.badRequest)
            }

            return try await ParkingApi.shared.getSessions(licensePlate: licensePlate)
        }

        route.post("start") { req async throws in
            guard let licensePlate = req.query[String.self, at: "licensePlate"],
                  let location = req.query[String.self, at: "location"],
                  let minutes = req.query[Int.self, at: "duration"] else
            {
                throw Abort(.badRequest)
            }

            let duration = Duration.minutes(Int64(minutes))
            try await ParkingApi.shared.startSession(licensePlate: licensePlate,
                                                     locationId: location,
                                                     duration: duration)
            return Response(status: .created)
        }

        route.post("end") { req async throws in
            guard let licensePlate = req.query[String.self, at: "licensePlate"] else {
                throw Abort(.badRequest)
            }

            try await ParkingApi.shared.stopSession(licensePlate: licensePlate)
            return Response(status: .ok)
        }
    }

    app.group("users") { route in
        route.get { req async throws in
            return await ParkingApi.shared.users.map { $0.asPrivate() }
        }

        route.get("add") { req async throws in
            guard let username = req.query[String.self, at: "username"],
                  let password = req.query[String.self, at: "password"],
                  let licensePlate = req.query[String.self, at: "licensePlate"] else
            {
                throw Abort(.badRequest)
            }

            let response = try await ParkingApi.shared.addUser(username: username,
                                                               password: password,
                                                               licensePlate: licensePlate)

            return Response(status: .accepted, body: .init(string: response))
        }

        route.get("remove") { req async throws in
            if let username = req.query[String.self, at: "username"] {
                let response = try await ParkingApi.shared.removeUser(username: username)
                return Response(status: .accepted, body: .init(string: response))
            }

            if let licensePlate = req.query[String.self, at: "licensePlate"] {
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

        return try await TicketApi.shared.checkForTickets(licensePlate: licensePlate)
    }

    app.get("tick") { req async throws in
        return Response(status: .ok)
    }
}
