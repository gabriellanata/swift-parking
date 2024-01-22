import Vapor

extension ParkingApi {
    func addUser(username: String, password: String, licensePlate: String) async throws -> String {
        let username = username.hasPrefix("+") ? username : "+1\(username)"
        let existingUser = self.users.first(where: { $0.username == username })
        if existingUser?.vehicles.contains(where: { $0.licensePlate == licensePlate }) == true {
            return "user_already_exists"
        }

        let vehicles = (existingUser?.vehicles ?? []) + [Vehicle(licensePlate: licensePlate)]
        let user = User(username: username, password: try password.encrypted(), vehicles: vehicles)
        self.users.removeAll(where: { $0.username == username })
        self.users.append(user)
        try await self.saveUsers()
        return "user_added"
    }

    func removeUser(username: String) async throws -> String {
        let username = username.hasPrefix("+") ? username : "+1\(username)"
        guard self.users.contains(where: { $0.username == username }) else {
            return "user_did_not_exist"
        }

        self.users.removeAll(where: { $0.username == username })
        try await self.saveUsers()
        return "user_removed"
    }

    func removeUsers(licensePlate: String) async throws -> String {
        guard self.users.contains(where: { $0.vehicles.contains(where: { $0.licensePlate == licensePlate }) }) else {
            return "users_did_not_exist"
        }

        self.users.removeAll(where: { $0.vehicles.contains(where: { $0.licensePlate == licensePlate }) })
        try await self.saveUsers()
        return "users_removed"
    }
}

extension ParkingApi {
    private static let usersFile = "Users.json"

    func saveUsers() async throws {
        try await Storage.shared.write(self.users, to: ParkingApi.usersFile)
    }

    func loadUsers() async throws {
        if let users = try await Storage.shared.read(ParkingApi.usersFile, type: [User].self) {
            self.users = users
        }
    }
}

// 300s block: 37303004

// User(username: "+14153238348", password: "RangerDanger88", vehicles: [
//     Vehicle(licensePlate: "8TLE881")
// ])

