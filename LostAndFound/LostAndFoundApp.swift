import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        
        return true
    }
}

@main
struct LostAndFoundApp: App {


    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var itemViewModel = ItemViewModel()

    init() {
            FirebaseApp.configure()
        }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(itemViewModel)
        }
    }
}


struct RootView: View {


    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var itemViewModel: ItemViewModel


    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                authenticatedView
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authViewModel.isLoggedIn)
    }

    @ViewBuilder
    private var authenticatedView: some View {
        if authViewModel.currentUser?.role == .admin {
            AdminTabView()
                .task { await loadData() }
        } else {
            MainTabView()
                .task { await loadData() }
        }
    }


    private func loadData() async {
        async let reports: () = itemViewModel.fetchAllReports()
        async let claims: () = itemViewModel.fetchAllClaims()
        _ = await (reports, claims)
    }
}
