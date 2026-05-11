import Foundation

final class AppStorageService {
    static let shared = AppStorageService()

    private let saveURL: URL = {
        let document = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return document.appendingPathComponent("moneycat-data.json")
    }()

    private init() {}

    func save(state: PersistedState) {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            print("Save failed: \(error)")
        }
    }

    func load() -> PersistedState {
        guard
            let data = try? Data(contentsOf: saveURL),
            let state = try? JSONDecoder().decode(PersistedState.self, from: data)
        else {
            return PersistedState(people: [], activities: [])
        }
        return state
    }
}

struct PersistedState: Codable {
    var people: [Person]
    var activities: [Activity]
}
