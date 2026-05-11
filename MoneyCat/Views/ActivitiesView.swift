import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var showingCreate = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(appViewModel.activities) { activity in
                    NavigationLink {
                        ActivityDetailView(activityID: activity.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(activity.name)
                                .font(.headline)
                            Text("参与人数：\(activity.participantIDs.count) · 订单数：\(activity.orders.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: appViewModel.removeActivities)
            }
            .overlay {
                if appViewModel.activities.isEmpty {
                    ContentUnavailableView("还没有活动", systemImage: "figure.socialdance", description: Text("点击右上角创建活动。"))
                }
            }
            .navigationTitle("活动")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateActivityView()
            }
        }
    }
}

private struct CreateActivityView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedParticipants: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List {
                Section("活动名称") {
                    TextField("例如：东京周末行", text: $title)
                }

                Section("参加人") {
                    ForEach(appViewModel.people) { person in
                        MultipleSelectionRow(
                            title: person.name,
                            isSelected: selectedParticipants.contains(person.id)
                        ) {
                            if selectedParticipants.contains(person.id) {
                                selectedParticipants.remove(person.id)
                            } else {
                                selectedParticipants.insert(person.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("创建活动")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        appViewModel.addActivity(name: title, participantIDs: Array(selectedParticipants))
                        dismiss()
                    }
                    .disabled(title.isEmpty || selectedParticipants.isEmpty)
                }
            }
        }
    }
}

struct MultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
