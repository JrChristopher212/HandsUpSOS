import Foundation
import CoreLocation
import SwiftUI

class LocationHelper: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var hasPermission = false
    @Published var locationText = "Checking location permission..."
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationPermission()
    }
    
    func checkLocationPermission() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            hasPermission = true
            locationText = "Location access granted"
            getCurrentLocation()
        case .denied, .restricted:
            hasPermission = false
            locationText = "Location access denied - Please enable in Settings"
        case .notDetermined:
            hasPermission = false
            locationText = "Location permission needed - Tap to allow"
        @unknown default:
            hasPermission = false
            locationText = "Unknown location permission status"
        }
    }
    
    func getCurrentLocation() {
        if hasPermission {
            locationManager.requestLocation()
            locationText = "Getting current location..."
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func getEmergencyLocationText() -> String {
        guard let location = currentLocation else {
            return "Location unavailable"
        }
        
        let latitude = String(format: "%.6f", location.coordinate.latitude)
        let longitude = String(format: "%.6f", location.coordinate.longitude)
        
        return "Lat: \(latitude), Long: \(longitude)"
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
            self.locationText = "Location: \(String(format: "%.4f", location.coordinate.latitude)), \(String(format: "%.4f", location.coordinate.longitude))"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationText = "Location access denied - Please enable in Settings"
                    self.hasPermission = false
                case .locationUnknown:
                    self.locationText = "Location unavailable - Please try again"
                case .network:
                    self.locationText = "Network error - Check internet connection"
                default:
                    self.locationText = "Location error: \(error.localizedDescription)"
                }
            } else {
                self.locationText = "Location error: \(error.localizedDescription)"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.checkLocationPermission()
        }
    }
}
