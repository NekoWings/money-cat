import Foundation

struct Order: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var date: Date
    var discountRate: Double
    var items: [ReceiptItem]

    init(
        id: UUID = UUID(),
        title: String,
        date: Date = .now,
        discountRate: Double = 0,
        items: [ReceiptItem] = []
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.discountRate = discountRate
        self.items = items
    }

    var subtotal: Decimal {
        items.reduce(0) { $0 + $1.amount }
    }

    var discountMultiplier: Decimal {
        max(0, min(1, Decimal(1 - discountRate / 100)))
    }

    var totalAfterDiscount: Decimal {
        (subtotal * discountMultiplier).rounded(scale: 2)
    }
}
