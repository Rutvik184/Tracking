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
    private var stopAfter: TimeInterval = 0 // Auto-stop duration (in ms)
    private var lastSentTime: Date = Date()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var timer: Timer?
    private var stopTimer: Timer? // Timer to schedule stop
    
    // MARK: - React Native exposed method
    @objc
    func startLogging(_ arg1: String,
                      arg2: String,
                      interval: NSNumber,
                      stopAfterMs: NSNumber,
                      resolver: @escaping RCTPromiseResolveBlock,
                      rejecter: @escaping RCTPromiseRejectBlock) {

        self.arg1 = arg1
        self.arg2 = arg2
        self.interval = interval.doubleValue / 1000 // ms → sec
        self.stopAfter = stopAfterMs.doubleValue / 1000 // ms → sec

        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager?.distanceFilter = kCLDistanceFilterNone

        // Request Always authorization
        if locationManager?.authorizationStatus == .notDetermined {
          locationManager?.requestAlwaysAuthorization()
        }

        // Enable background updates
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false

        // Start normal + significant updates
        locationManager?.startUpdatingLocation()
        locationManager?.startMonitoringSignificantLocationChanges()

        // Start periodic timer
        beginBackgroundTask()

        // Schedule auto stop if duration > 0
        if stopAfter > 0 {
            scheduleStop(after: stopAfter)
        }

        resolver("iOS Location Service Started")
        print("📍 Location Service Started — interval: \(interval)s, stop after: \(stopAfter)s")
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        sendLocation(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location Error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("🔐 Authorization Status: \(status.rawValue)")
    }

    // MARK: - Send location to JS
    private func sendLocation(_ location: CLLocation) {
      let formatter = DateFormatter()
          formatter.dateFormat = "HH:mm:ss"
          let timeString = formatter.string(from: Date())

          print("📤 [\(timeString)] Sent -> Arg1: \(arg1 ?? ""), Arg2: \(arg2 ?? ""), Lat: \(location.coordinate.latitude), Lng: \(location.coordinate.longitude)")
    }

    // MARK: - Background Task + Timer
    private func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "LocationTask") {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }

        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: self.interval, repeats: true) { _ in
                if let loc = self.locationManager?.location {
                    self.sendLocation(loc)
                }
            }
        }
    }

    private func endBackgroundTask() {
        timer?.invalidate()
        timer = nil
        stopTimer?.invalidate()
        stopTimer = nil

        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    // MARK: - Schedule Auto Stop
    private func scheduleStop(after seconds: TimeInterval) {
        DispatchQueue.main.async {
            self.stopTimer?.invalidate()
            self.stopTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
                print("⏱ Auto-stopping after \(seconds) seconds")
                self.stopLogging({ _ in }, rejecter: { _, _, _ in })
            }
        }
    }

    // MARK: - Manual Stop
    @objc
    func stopLogging(_ resolver: @escaping RCTPromiseResolveBlock,
                     rejecter: @escaping RCTPromiseRejectBlock) {

        endBackgroundTask()
        locationManager?.stopUpdatingLocation()
        locationManager?.stopMonitoringSignificantLocationChanges()

        resolver("iOS Location Service Stopped")
        print("🛑 Location logging stopped manually or automatically")
    }

    // MARK: - React Native setup
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

