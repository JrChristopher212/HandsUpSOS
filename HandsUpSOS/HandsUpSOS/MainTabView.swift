import SwiftUI

struct MainTabView: View {
    @StateObject private var contactHelper = ContactHelper()
    @StateObject private var locationHelper = LocationHelper()
    @StateObject private var campsiteManager = CampsiteManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Emergency SOS Tab
            ContentView(locationHelper: locationHelper, contactHelper: contactHelper, campsiteManager: campsiteManager)
                .tabItem {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Emergency SOS")
                }
                .tag(0)
            
            // Campsites Tab
            CampsiteMapView(campsiteManager: campsiteManager)
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Campsites")
                }
                .tag(1)
            
            // Campsite List Tab
            CampsiteListView(campsiteManager: campsiteManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("My Campsites")
                }
                .tag(2)
            
            // Settings Tab
            SettingsView(locationHelper: locationHelper, contactHelper: contactHelper)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .tag(4)
            
        }
        .accentColor(.gray) // Make all tabs the same color
        .toolbar(selectedTab == 0 ? .hidden : .visible, for: .tabBar)
    }
}

#Preview {
    MainTabView()
}
