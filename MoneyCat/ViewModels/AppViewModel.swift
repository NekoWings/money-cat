import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var people: [Person] = [] {
        didSet { persist() }
    }

    @Published var activities: [Activity] = [] {
        didSet { persist() }
    }

    private let storage = AppStorageService.shared

    init() {
        let state = storage.load()
        self.people = state.people
        self.activities = state.activities

        if people.isEmpty {
            people = [Person(name: "小明"), Person(name: "小红"), Person(name: "小刚")]
        }
    }

    // MARK: - People

    func addPerson(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !people.contains(where: { $0.name == trimmed }) else { return }
        people.append(Person(name: trimmed))
    }

    func renamePerson(id: UUID, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let index = people.firstIndex(where: { $0.id == id }) else { return }
        people[index].name = trimmed
    }

    func removePeople(at offsets: IndexSet) {
        let removedIDs = offsets.map { people[$0].id }
        people.remove(atOffsets: offsets)

        // remove deleted people from activities and order allocations
        for index in activities.indices {
            activities[index].participantIDs.removeAll(where: { removedIDs.contains($0) })
            for orderIndex in activities[index].orders.indices {
                for itemIndex in activities[index].orders[orderIndex].items.indices {
                    activities[index].orders[orderIndex].items[itemIndex].participantShares.removeAll {
                        removedIDs.contains($0.personID)
                    }

                    if removedIDs.contains(activities[index].orders[orderIndex].items[itemIndex].payerID),
                       let fallback = activities[index].participantIDs.first {
                        activities[index].orders[orderIndex].items[itemIndex].payerID = fallback
                    }
                }
            }
        }
    }

    // MARK: - Activity

    func addActivity(name: String, participantIDs: [UUID]) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !participantIDs.isEmpty else { return }
        activities.append(Activity(name: trimmed, participantIDs: participantIDs))
    }

    func removeActivities(at offsets: IndexSet) {
        activities.remove(atOffsets: offsets)
    }

    func activity(by id: UUID) -> Activity? {
        activities.first(where: { $0.id == id })
    }

    // MARK: - Order

    func addOrder(to activityID: UUID, order: Order) {
        guard let index = activities.firstIndex(where: { $0.id == activityID }) else { return }
        activities[index].orders.append(order)
    }

    func updateOrder(activityID: UUID, order: Order) {
        guard let activityIndex = activities.firstIndex(where: { $0.id == activityID }) else { return }
        guard let orderIndex = activities[activityIndex].orders.firstIndex(where: { $0.id == order.id }) else { return }
        activities[activityIndex].orders[orderIndex] = order
    }

    func deleteOrder(activityID: UUID, offsets: IndexSet) {
        guard let index = activities.firstIndex(where: { $0.id == activityID }) else { return }
        activities[index].orders.remove(atOffsets: offsets)
    }

    // MARK: - Helpers

    func personName(for id: UUID) -> String {
        people.first(where: { $0.id == id })?.name ?? "未知"
    }

    func peopleForActivity(_ activity: Activity) -> [Person] {
        people.filter { activity.participantIDs.contains($0.id) }
    }

    private func persist() {
        storage.save(state: PersistedState(people: people, activities: activities))
    }
}
