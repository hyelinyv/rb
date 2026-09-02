import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("首页", systemImage: "house.fill") }

            NavigationStack {
                LibraryView()
            }
            .tabItem { Label("书库", systemImage: "books.vertical") }

            NavigationStack {
                ReportView()
            }
            .tabItem { Label("报告", systemImage: "chart.bar.fill") }

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("我的", systemImage: "person.fill") }
        }
        .tint(.black)
    }
}
