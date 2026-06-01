import Foundation

protocol BeachStoring: Sendable {
    func save(_ beach: Beach) async throws
    func fetchAll() async throws -> [Beach]
    func delete(_ identifier: Beach.ID) async throws
    func fetch(identifier: Beach.ID) async throws -> Beach?
}

actor FileBeachStore: BeachStoring {
    private let fileURL: URL
    private var cache: [Beach]?

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("beaches.json")
    }

    func save(_ beach: Beach) async throws {
        var beaches = try await fetchAll()
        if let index = beaches.firstIndex(where: { $0.id == beach.id }) {
            beaches[index] = beach
        } else {
            beaches.append(beach)
        }
        try persist(beaches)
    }

    func fetchAll() async throws -> [Beach] {
        if let cache { return cache }
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let beaches = try? JSONDecoder().decode([Beach].self, from: data) else {
            return []
        }
        cache = beaches
        return beaches
    }

    func delete(_ identifier: Beach.ID) async throws {
        var beaches = try await fetchAll()
        beaches.removeAll { $0.id == identifier }
        try persist(beaches)
    }

    func fetch(identifier: Beach.ID) async throws -> Beach? {
        try await fetchAll().first { $0.id == identifier }
    }

    private func persist(_ beaches: [Beach]) throws {
        let data = try JSONEncoder().encode(beaches)
        try data.write(to: fileURL, options: .atomic)
        cache = beaches
    }
}
