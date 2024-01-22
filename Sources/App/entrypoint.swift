import Vapor
import Logging

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = Application(env)
        defer { app.shutdown() }
        
        do {
            try await configure(app)
        } catch {
            app.logger.report(error: error)
            throw error
        }

        try await app.execute()
    }

    public static func configure(_ app: Application) async throws {
        try await Storage.shared.initialize(app: app)
        try await Security.shared.initialize()
        try await Api.shared.initialize(client: app.client)
        try await ParkingApi.shared.initialize()
        routes(app)
    }
}
