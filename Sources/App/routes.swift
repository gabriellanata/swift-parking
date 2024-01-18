import Vapor

struct Session {
    let licensePlate: String
}

actor Storage {
    var activeSessions: [Session] = []

    func startSession(_ session: Session) {
        activeSessions.append(session)
    }

    func endSession(licensePlate: String) {
        activeSessions.removeAll { $0.licensePlate == licensePlate }
    }
}

private let storage = Storage()

func routes(_ app: Application) {
    app.get { req async throws in
        return """
            Active Sessions:
            \(await storage.activeSessions.map { "- \($0.licensePlate)" }.joined(separator: "\n"))
            """
    }

    app.get("start") { req async throws -> String in
        guard let licensePlate = req.query[String.self, at: "licensePlate"] else {
            throw Abort(.badRequest)
        }
        
        await storage.startSession(Session(licensePlate: licensePlate))
        return "Started session: \(licensePlate)"
    }

    app.get("stop") { req async throws -> String in
        guard let licensePlate = req.query[String.self, at: "licensePlate"] else {
            throw Abort(.badRequest)
        }

        await storage.endSession(licensePlate: licensePlate)
        return "Stopped session: \(licensePlate)"
    }
}
