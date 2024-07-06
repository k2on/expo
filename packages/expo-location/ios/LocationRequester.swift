// Copyright 2024-present 650 Industries. All rights reserved.

import CoreLocation

internal class LocationRequester: NSObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var continuation: CheckedContinuation<CLLocation, Error>?

  // CLLocationManager must be created on the main thread.
  @MainActor
  init(options: LocationOptions) {
    super.init()
    manager.allowsBackgroundLocationUpdates = false
    manager.distanceFilter = options.distanceInterval
    manager.desiredAccuracy = options.accuracy.toCLLocationAccuracy()
    manager.delegate = self
  }

  func requestLocation() async throws -> CLLocation {
    return try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation
      manager.requestLocation()
    }
  }

  // MARK: - CLLocationManagerDelegate

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let lastLocation = locations.last {
      continuation?.resume(returning: lastLocation)
    } else {
      continuation?.resume(throwing: LocationUnavailableException())
    }
    continuation = nil
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
    continuation?.resume(throwing: LocationUnavailableException().causedBy(error))
    continuation = nil
  }
}
