// Copyright 2024-present 650 Industries. All rights reserved.

import CoreLocation

internal class LocationsStreamer: NSObject, CLLocationManagerDelegate {
  typealias LocationsStream = AsyncThrowingStream<[CLLocation], Error>

  private let manager = CLLocationManager()
  private var locationsStream: LocationsStream?
  private var continuation: LocationsStream.Continuation?

  // CLLocationManager must be created on the main thread.
  @MainActor
  init(options: LocationOptions) {
    super.init()
    manager.allowsBackgroundLocationUpdates = false
    manager.distanceFilter = options.distanceInterval
    manager.desiredAccuracy = options.accuracy.toCLLocationAccuracy()
    manager.delegate = self
  }

  func streamLocations() -> LocationsStream {
    let stream = LocationsStream { continuation in
      self.continuation = continuation
      manager.startUpdatingLocation()
    }
    locationsStream = stream
    return stream
  }

  func stopStreaming() {
    manager.stopUpdatingLocation()
    continuation?.finish()

    locationsStream = nil
    continuation = nil
  }

  // MARK: - CLLocationManagerDelegate

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if !locations.isEmpty {
      continuation?.yield(locations)
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
    continuation?.finish(throwing: LocationUnavailableException().causedBy(error))
    locationsStream = nil
    continuation = nil
  }
}
