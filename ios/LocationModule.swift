import Foundation
import CoreLocation
import React
import UIKit

@objc(LocationModule)
class LocationModule: RCTEventEmitter, CLLocationManagerDelegate {

    private var locationManager: CLLocationManager?
    private var arg1: String?
    private var arg2: String?
    private var interval: TimeInterval = 1
    private var lastSentTime: Date = Date()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var timer: Timer?
    
    // MARK: - React Native exposed method
    @objc
    func startLogging(_ arg1: String, arg2: String, interval: NSNumber,
                      resolver: @escaping RCTPromiseResolveBlock,
                      rejecter: @escaping RCTPromiseRejectBlock) {
        
        self.arg1 = arg1
        self.arg2 = arg2
        self.interval = interval.doubleValue / 1000 // convert ms to seconds
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager?.distanceFilter = kCLDistanceFilterNone
        
        // Request Always authorization
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager?.requestAlwaysAuthorization()
        }
        
        // Enable background updates
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
        
        // Start normal updates
        locationManager?.startUpdatingLocation()
        
        // Start Significant Location Change for background reliability
        locationManager?.startMonitoringSignificantLocationChanges()
        
        // Start background timer to send location periodically even if device is stationary
        beginBackgroundTask()
        
        resolver("iOS Location Service Started")
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        sendLocation(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("Authorization Status: \(status.rawValue)")
    }
    
    // MARK: - Send location to JS
    private func sendLocation(_ location: CLLocation) {
                  
      print("Location Sent -> Arg1: \(arg1 ?? ""), Arg2: \(arg2 ?? ""), Lat: \(location.coordinate.latitude), Lng: \(location.coordinate.longitude)")
    }
    
    // MARK: - Background Task + Timer
    private func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "LocationTask") {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }
        
        // Timer fires every 1 sec to check location
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: self.interval, repeats: true) { _ in
                if let loc = self.locationManager?.location {
                  print("Location Sent ->Lat: \(loc.coordinate.latitude), Lng: \(loc.coordinate.longitude)")
                    self.sendLocation(loc)
                }
            }
        }
    }
    
    private func endBackgroundTask() {
        timer?.invalidate()
        timer = nil
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
  
  @objc
  func stopLogging(_ resolver: @escaping RCTPromiseResolveBlock,
                   rejecter: @escaping RCTPromiseRejectBlock) {
      
      // Stop background timer
      timer?.invalidate()
      timer = nil
      
      // End background task
      if backgroundTask != .invalid {
          UIApplication.shared.endBackgroundTask(backgroundTask)
          backgroundTask = .invalid
      }
      
      // Stop location updates
      locationManager?.stopUpdatingLocation()
      locationManager?.stopMonitoringSignificantLocationChanges()
      
      resolver("iOS Location Service Stopped")
      print("Location logging stopped")
  }

    
    @objc
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    deinit {
        endBackgroundTask()
        locationManager?.stopUpdatingLocation()
        locationManager?.stopMonitoringSignificantLocationChanges()
    }
}

