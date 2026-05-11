import Foundation

struct Activity: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var participantIDs: [UUID]
    var orders: [Order]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        participantIDs: [UUID],
        orders: [Order] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.participantIDs = participantIDs
        self.orders = orders
        self.createdAt = createdAt
    }
}

struct Settlement: Identifiable {
    let id = UUID()
    let debtorID: UUID
    let creditorID: UUID
    let amount: Decimal
}
