import PhotosUI
import SwiftUI
import UIKit

struct OrderEditorView: View {
    enum Mode {
        case create
        case edit(Order)
    }

    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    let activity: Activity
    let mode: Mode

    @State private var orderID = UUID()
    @State private var title = ""
    @State private var discountRate: Double = 0
    @State private var items: [ReceiptItem] = []
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isScanning = false
    @State private var errorText: String?

    private let ocr = OCRService()

    init(activity: Activity, mode: Mode) {
        self.activity = activity
        self.mode = mode

        if case let .edit(order) = mode {
            _orderID = State(initialValue: order.id)
            _title = State(initialValue: order.title)
            _discountRate = State(initialValue: order.discountRate)
            _items = State(initialValue: order.items)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("订单信息") {
                    TextField("订单标题", text: $title)
                    HStack {
                        Text("折扣(%)")
                        Slider(value: $discountRate, in: 0...100, step: 1)
                        Text("\(Int(discountRate))")
                            .monospacedDigit()
                    }
                }

                Section("导入小票") {
                    Button("使用文档相机扫描") { isScanning = true }
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Text("从相册选择小票")
                    }
                }

                if let errorText {
                    Section {
                        Text(errorText).foregroundStyle(.red)
                    }
                }

                Section("项目分配") {
                    Button {
                        addManualItem()
                    } label: {
                        Label("手动添加项目", systemImage: "plus")
                    }

                    ForEach($items) { $item in
                        ReceiptItemEditor(item: $item, candidates: participants)
                    }
                    .onDelete(perform: removeItems)
                }
            }
            .navigationTitle(modeTitle)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存", action: save)
                        .disabled(!canSave)
                }
            }
            .task(id: selectedPhoto) {
                await loadFromPhotoPicker()
            }
            .sheet(isPresented: $isScanning) {
                LiveScannerView { image in
                    Task { await applyOCR(on: image) }
                }
            }
        }
    }

    private var modeTitle: String {
        switch mode {
        case .create: return "新订单"
        case .edit: return "编辑订单"
        }
    }

    private var participants: [Person] {
        appViewModel.peopleForActivity(activity)
    }

    private var canSave: Bool {
        !items.isEmpty && items.allSatisfy { !$0.name.isEmpty && $0.amount > 0 && !$0.participantShares.isEmpty }
    }

    private func save() {
        let order = Order(
            id: orderID,
            title: title.isEmpty ? "未命名订单" : title,
            date: .now,
            discountRate: discountRate,
            items: items
        )

        switch mode {
        case .create:
            appViewModel.addOrder(to: activity.id, order: order)
        case .edit:
            appViewModel.updateOrder(activityID: activity.id, order: order)
        }
        dismiss()
    }

    private func addManualItem() {
        guard let defaultPayer = participants.first?.id else { return }
        let shares = participants.map { ParticipantShare(personID: $0.id, weight: 1) }
        items.append(
            ReceiptItem(
                name: "",
                amount: 0,
                payerID: defaultPayer,
                allocationMethod: .equal,
                participantShares: shares
            )
        )
    }

    private func removeItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    private func loadFromPhotoPicker() async {
        guard let selectedPhoto else { return }
        do {
            guard let data = try await selectedPhoto.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorText = "图片读取失败"
                return
            }
            await applyOCR(on: image)
        } catch {
            errorText = "OCR失败：\(error.localizedDescription)"
        }
    }

    @MainActor
    private func applyOCR(on image: UIImage) async {
        do {
            let extracted = try await ocr.recognizeReceiptItems(from: image)
            guard let defaultPayer = participants.first?.id else { return }
            let defaultShares = participants.map { ParticipantShare(personID: $0.id, weight: 1) }

            let parsed: [ReceiptItem] = extracted.map {
                ReceiptItem(
                    name: $0.name,
                    amount: $0.amount,
                    payerID: defaultPayer,
                    allocationMethod: .equal,
                    participantShares: defaultShares
                )
            }

            if !parsed.isEmpty {
                items.append(contentsOf: parsed)
                if title.isEmpty { title = "扫描订单" }
                errorText = nil
            } else {
                errorText = "未识别到可用条目，请手动补充。"
            }
        } catch {
            errorText = "OCR失败：\(error.localizedDescription)"
        }
    }
}

private struct ReceiptItemEditor: View {
    @Binding var item: ReceiptItem
    let candidates: [Person]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("项目", text: $item.name)
            HStack {
                Text("金额")
                TextField("0.00", value: $item.amount, format: .number)
                    .keyboardType(.decimalPad)
            }

            Picker("付款人", selection: $item.payerID) {
                ForEach(candidates) { person in
                    Text(person.name).tag(person.id)
                }
            }

            Picker("分摊方式", selection: $item.allocationMethod) {
                ForEach(AllocationMethod.allCases) { method in
                    Text(method.displayName).tag(method)
                }
            }

            ForEach(candidates) { person in
                if let index = item.participantShares.firstIndex(where: { $0.personID == person.id }) {
                    HStack {
                        Toggle(person.name, isOn: Binding(
                            get: { item.participantShares[index].weight > 0 },
                            set: { enabled in
                                item.participantShares[index].weight = enabled ? max(1, item.participantShares[index].weight) : 0
                            }
                        ))

                        if item.allocationMethod == .weighted {
                            Stepper(
                                "权重 \(Int(item.participantShares[index].weight))",
                                value: $item.participantShares[index].weight,
                                in: 0...10,
                                step: 1
                            )
                            .frame(maxWidth: 180)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}
