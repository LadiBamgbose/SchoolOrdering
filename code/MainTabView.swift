import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var userEmailManager: UserEmailManager
    @StateObject private var cart = Cart()
    @State private var userEmail: String = ""
    @State private var isLoggedIn: Bool = false

    init(userEmail: String) {
        _userEmail = State(initialValue: userEmail)
    }

    var body: some View {
        TabView {
            menuPage()
                .tabItem {
                    Text("Menu")
                    Image(systemName: "menucard")
                }

            Account(userEmail: $userEmail)
                .tabItem {
                    Text("Account")
                    Image(systemName: "person")
                }
                .environmentObject(userEmailManager)

            PastOrdersView(cart: cart)
                .tabItem {
                    Text("Order History")
                    Image(systemName: "arrow.clockwise")
                }

            CartView(cart: cart)
                .tabItem {
                    Label("Cart", systemImage: "cart")
                }
                .environmentObject(userEmailManager)
        }
        .environmentObject(cart)
        .overlay(
            Badge(number: cart.totalItems)
                .offset(x: 165, y: 340)
                .opacity(cart.totalItems > 0 ? 1.0 : 0.0)
        )
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(userEmail: "example@sju.edu")
            .environmentObject(UserEmailManager.shared)
    }
}
