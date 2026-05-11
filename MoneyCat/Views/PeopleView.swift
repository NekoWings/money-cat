import SwiftUI

struct PeopleView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @State private var newName = ""
    @State private var editingPerson: Person?

    var body: some View {
        NavigationStack {
            List {
                Section("添加成员") {
                    TextField("输入姓名", text: $newName)
                    Button("创建") {
                        appViewModel.addPerson(name: newName)
                        newName = ""
                    }
                }

                Section("已有成员") {
                    ForEach(appViewModel.people) { person in
                        HStack {
                            Text(person.name)
                            Spacer()
                            Button("编辑") {
                                editingPerson = person
                            }
                            .font(.caption)
                        }
                    }
                    .onDelete(perform: appViewModel.removePeople)
                }
            }
            .navigationTitle("人员管理")
            .toolbar {
                EditButton()
            }
            .sheet(item: $editingPerson) { person in
                RenamePersonSheet(person: person)
            }
        }
    }
}

private struct RenamePersonSheet: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    let person: Person
    @State private var newName: String

    init(person: Person) {
        self.person = person
        _newName = State(initialValue: person.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("姓名", text: $newName)
            }
            .navigationTitle("编辑成员")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        appViewModel.renamePerson(id: person.id, newName: newName)
                        dismiss()
                    }
                }
            }
        }
    }
}
