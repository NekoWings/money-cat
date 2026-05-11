import SwiftUI

struct ActivityDetailView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    let activityID: UUID
    @State private var showingNewOrder = false
    @State private var editingOrder: Order?

    private var activity: Activity? {
        appViewModel.activity(by: activityID)
    }

    var body: some View {
        List {
            if let activity {
                Section("参与人") {
                    ForEach(appViewModel.peopleForActivity(activity)) { person in
                        Text(person.name)
                    }
                }

                Section("订单") {
                    if activity.orders.isEmpty {
                        Text("暂无订单")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(activity.orders) { order in
                        Button {
                            editingOrder = order
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(order.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("小计：\(order.subtotal.currencyText)  折扣：\(Int(order.discountRate))%  实付：\(order.totalAfterDiscount.currencyText)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        appViewModel.deleteOrder(activityID: activity.id, offsets: offsets)
                    }
                }

                BalanceSummaryView(activity: activity)
                SettlementSummaryView(activity: activity)
            }
        }
        .navigationTitle(activity?.name ?? "活动")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewOrder = true
                } label: {
                    Image(systemName: "plus.rectangle.on.folder")
                }
            }
        }
        .sheet(isPresented: $showingNewOrder) {
            if let activity {
                OrderEditorView(activity: activity, mode: .create)
            }
        }
        .sheet(item: $editingOrder) { order in
            if let activity {
                OrderEditorView(activity: activity, mode: .edit(order))
            }
        }
    }
}

private struct BalanceSummaryView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    let activity: Activity

    var body: some View {
        Section("净额") {
            let balances = SettlementCalculator.balances(for: activity)
            if balances.isEmpty {
                Text("暂无数据")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(appViewModel.peopleForActivity(activity)) { person in
                    let amount = balances[person.id, default: 0]
                    HStack {
                        Text(person.name)
                        Spacer()
                        Text(amount.currencyText)
                            .foregroundStyle(amount < 0 ? .red : .green)
                    }
                }
            }
        }
    }
}

private struct SettlementSummaryView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    let activity: Activity

    var body: some View {
        Section("结算明细") {
            let settlements = SettlementCalculator.settlements(for: activity)
            if settlements.isEmpty {
                Text("暂无结算数据")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(settlements) { settlement in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(appViewModel.personName(for: settlement.debtorID)) → \(appViewModel.personName(for: settlement.creditorID))")
                        Text(settlement.amount.currencyText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
