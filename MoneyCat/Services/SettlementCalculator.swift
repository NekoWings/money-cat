import Foundation

enum SettlementCalculator {
    static func settlements(for activity: Activity) -> [Settlement] {
        var transfers: [UUID: [UUID: Decimal]] = [:]

        for order in activity.orders {
            let multiplier = order.discountMultiplier

            for item in order.items {
                let discountedAmount = (item.amount * multiplier).rounded(scale: 2)
                let shares = normalizedShares(item.participantShares, method: item.allocationMethod)
                guard !shares.isEmpty else { continue }

                for share in shares {
                    let owed = (discountedAmount * share.weight).rounded(scale: 2)
                    guard share.personID != item.payerID else { continue }

                    var debtorMap = transfers[share.personID, default: [:]]
                    debtorMap[item.payerID, default: 0] += owed
                    transfers[share.personID] = debtorMap
                }
            }
        }

        return flattenTransfers(transfers)
            .filter { $0.amount > 0 }
            .sorted {
                if $0.debtorID == $1.debtorID {
                    return $0.creditorID.uuidString < $1.creditorID.uuidString
                }
                return $0.debtorID.uuidString < $1.debtorID.uuidString
            }
    }

    static func balances(for activity: Activity) -> [UUID: Decimal] {
        var result: [UUID: Decimal] = [:]
        for settlement in settlements(for: activity) {
            result[settlement.debtorID, default: 0] -= settlement.amount
            result[settlement.creditorID, default: 0] += settlement.amount
        }
        return result
    }

    private static func normalizedShares(_ shares: [ParticipantShare], method: AllocationMethod) -> [ParticipantShare] {
        let positiveShares: [ParticipantShare]
        switch method {
        case .equal:
            positiveShares = shares.map { ParticipantShare(personID: $0.personID, weight: 1) }
        case .weighted:
            positiveShares = shares.filter { $0.weight > 0 }
        }

        let totalWeight = positiveShares.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return [] }

        return positiveShares.map {
            ParticipantShare(personID: $0.personID, weight: $0.weight / totalWeight)
        }
    }

    private static func flattenTransfers(_ map: [UUID: [UUID: Decimal]]) -> [Settlement] {
        map.flatMap { debtor, creditors in
            creditors.map { creditor, amount in
                Settlement(debtorID: debtor, creditorID: creditor, amount: amount.rounded(scale: 2))
            }
        }
    }
}
