// Copyright 2023-present 650 Industries. All rights reserved.

import CoreLocation

internal final class LocationManager: NSObject, CLLocationManagerDelegate {
  typealias UpdateLocationsCallback = ([CLLocation]) -> Void
  typealias UpdateHeadingCallback = (CLHeading) -> Void
  typealias ErrorCallback = (NSError) -> Void

  private static var retainedManagers = Set<LocationManager>()

  private let manager = CLLocationManager()

  init(options: LocationOptions) {
    super.init()
    manager.allowsBackgroundLocationUpdates = false
    manager.distanceFilter = options.distanceInterval
    manager.desiredAccuracy = options.accuracy.toCLLocationAccuracy()
    manager.delegate = self
  }

  // MARK: - Callbacks

  internal var onUpdateLocations: UpdateLocationsCallback? {
    didSet {
      if onUpdateLocations != nil {
        manager.startUpdatingLocation()
      } else {
        manager.stopUpdatingLocation()
      }
    }
  }

  internal var onUpdateHeading: UpdateHeadingCallback? {
    didSet {
      if onUpdateHeading != nil {
        manager.startUpdatingHeading()
      } else {
        manager.stopUpdatingHeading()
      }
    }
  }

  internal var onError: ErrorCallback?

  // MARK: - Functionality

  internal func requestLocation() {
    manager.requestLocation()
  }

  // MARK: - Retaining

  internal func retain() -> Self {
    Self.retainedManagers.insert(self)
    return self
  }

  internal func release() {
    onUpdateLocations = nil
    onUpdateHeading = nil
    Self.retainedManagers.remove(self)
  }

  // MARK: - CLLocationManagerDelegate

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    onUpdateLocations?(locations)
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    onUpdateHeading?(newHeading)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    onError?(error as NSError)
  }
}
