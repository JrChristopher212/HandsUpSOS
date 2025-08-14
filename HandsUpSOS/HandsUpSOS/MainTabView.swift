import SwiftUI

struct MainTabView: View {
    @StateObject private var contactHelper = ContactHelper()
    @StateObject private var locationHelper = LocationHelper()
    @StateObject private var campsiteManager = CampsiteManager()
    
    var body: some View {
        TabView {
            // Emergency SOS Tab
            ContentView(locationHelper: locationHelper, contactHelper: contactHelper)
                .tabItem {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Emergency SOS")
                }
            
            // Campsites Tab
            CampsiteMapView(campsiteManager: campsiteManager)
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Campsites")
                }
            
            // Campsite List Tab
            CampsiteListView(campsiteManager: campsiteManager)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("My Campsites")
                }
        }
        .accentColor(.red) // Emergency theme color
    }
}

#Preview {
    MainTabView()
}
