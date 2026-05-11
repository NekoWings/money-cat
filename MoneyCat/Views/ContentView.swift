import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ActivitiesView()
                .tabItem {
                    Label("活动", systemImage: "list.bullet.rectangle")
                }

            PeopleView()
                .tabItem {
                    Label("人员", systemImage: "person.3")
                }
        }
    }
}
