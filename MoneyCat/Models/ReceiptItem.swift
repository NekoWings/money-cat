import Foundation

enum AllocationMethod: String, Codable, CaseIterable, Identifiable {
    case equal
    case weighted

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .equal: return "均分"
        case .weighted: return "按份额"
        }
    }
}

struct ParticipantShare: Identifiable, Codable, Hashable {
    let id: UUID
    var personID: UUID
    var weight: Double

    init(id: UUID = UUID(), personID: UUID, weight: Double = 1) {
        self.id = id
        self.personID = personID
        self.weight = weight
    }
}

struct ReceiptItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var amount: Decimal
    var payerID: UUID
    var allocationMethod: AllocationMethod
    var participantShares: [ParticipantShare]

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        payerID: UUID,
        allocationMethod: AllocationMethod = .equal,
        participantShares: [ParticipantShare]
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.payerID = payerID
        self.allocationMethod = allocationMethod
        self.participantShares = participantShares
    }
}
