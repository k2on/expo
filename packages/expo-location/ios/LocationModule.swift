// Copyright 2023-present 650 Industries. All rights reserved.

import CoreLocation
import ExpoModulesCore

fileprivate let EVENT_LOCATION_CHANGED = "Expo.locationChanged"
fileprivate let EVENT_HEADING_CHANGED = "Expo.headingChanged"

public final class LocationModule: Module {
  private lazy var watchedManagers = [Int: LocationManager]()
  private lazy var locationStreamers = [Int: LocationsStreamer]()

  private var taskManager: EXTaskManagerInterface {
    get throws {
      guard let taskManager: EXTaskManagerInterface = appContext?.legacyModule(implementing: EXTaskManagerInterface.self) else {
        throw TaskManagerUnavailableException()
      }
      return taskManager
    }
  }

  public func definition() -> ModuleDefinition {
    Name("ExpoLocation")

    Events(EVENT_LOCATION_CHANGED, EVENT_HEADING_CHANGED)

    AsyncFunction("getProviderStatusAsync") {
      return [
        "locationServicesEnabled": CLLocationManager.locationServicesEnabled(),
        "backgroundModeEnabled": true
      ]
    }

    AsyncFunction("getCurrentPositionAsync") { (options: LocationOptions) in
      try ensureForegroundLocationPermissions(appContext)

      let requester = await LocationRequester(options: options)
      let location = try await requester.requestLocation()

      return exportLocation(location)
    }

    AsyncFunction("watchPositionImplAsync") { (watchId: Int, options: LocationOptions) in
      try ensureForegroundLocationPermissions(appContext)

      let streamer = await LocationsStreamer(options: options)

      locationStreamers[watchId] = streamer

      for try await locations in streamer.streamLocations() {
        guard let location = locations.last else {
          continue
        }
        sendEvent(EVENT_LOCATION_CHANGED, [
          "watchId": watchId,
          "location": exportLocation(location)
        ])
      }
    }

    AsyncFunction("getLastKnownPositionAsync") { (requirements: LastKnownLocationRequirements) -> [String: Any]? in
      try ensureForegroundLocationPermissions(appContext)

      if let location = CLLocationManager().location, isLocation(location, valid: requirements) {
        return exportLocation(location)
      }
      return nil
    }

    AsyncFunction("watchDeviceHeading") { (watchId: Int, promise: Promise) in
      try ensureForegroundLocationPermissions(appContext)

      let options = LocationOptions(accuracy: .bestForNavigation, distanceInterval: 0)
      let manager = LocationManager(options: options)

      manager.onUpdateHeading = { (heading: CLHeading) in
        let accuracy = normalizeAccuracy(heading.headingAccuracy)

        self.sendEvent(EVENT_HEADING_CHANGED, [
          "watchId": watchId,
          "heading": [
            "trueHeading": heading.trueHeading,
            "magHeading": heading.magneticHeading,
            "accuracy": accuracy
          ]
        ])
      }
      watchedManagers[watchId] = manager.retain()
    }

    AsyncFunction("removeWatchAsync") { (watchId: Int) in
      if let streamer = locationStreamers[watchId] {
        streamer.stopStreaming()
        locationStreamers[watchId] = nil
      }
      if let manager = watchedManagers[watchId] {
        watchedManagers[watchId] = nil
        manager.release()
      }
    }

    AsyncFunction("geocodeAsync") { (address: String) in
      return try await Geocoder.geocode(address: address)
    }

    AsyncFunction("reverseGeocodeAsync") { (location: CLLocation) in
      return try await Geocoder.reverseGeocode(location: location)
    }

    AsyncFunction("getPermissionsAsync") { (promise: Promise) in
      try getPermissionUsingRequester(EXLocationPermissionRequester.self, appContext: appContext, promise: promise)
    }

    AsyncFunction("requestPermissionsAsync") { (promise: Promise) in
      try askForPermissionUsingRequester(EXLocationPermissionRequester.self, appContext: appContext, promise: promise)
    }

    AsyncFunction("getForegroundPermissionsAsync") { (promise: Promise) in
      try getPermissionUsingRequester(EXForegroundPermissionRequester.self, appContext: appContext, promise: promise)
    }

    AsyncFunction("requestForegroundPermissionsAsync") { (promise: Promise) in
      try askForPermissionUsingRequester(EXForegroundPermissionRequester.self, appContext: appContext, promise: promise)
    }

    AsyncFunction("getBackgroundPermissionsAsync") { (promise: Promise) in
      try getPermissionUsingRequester(EXBackgroundLocationPermissionRequester.self, appContext: appContext, promise: promise)
    }

    AsyncFunction("requestBackgroundPermissionsAsync") { (promise: Promise) in
      try askForPermissionUsingRequester(EXBackgroundLocationPermissionRequester.self, appContext: appContext, promise: promise)
    }

    AsyncFunction("hasServicesEnabledAsync") {
      return CLLocationManager.locationServicesEnabled()
    }

    // Background location

    AsyncFunction("startLocationUpdatesAsync") { (taskName: String, options: [String: Any]) in
      try ensureLocationServicesEnabled()
      try ensureForegroundLocationPermissions(appContext)
      try ensureBackgroundLocationPermissions(appContext)
      guard CLLocationManager.significantLocationChangeMonitoringAvailable() else {
        throw LocationUpdatesUnavailableException()
      }

      try taskManager.registerTask(withName: taskName, consumer: EXLocationTaskConsumer.self, options: options)
    }

    AsyncFunction("stopLocationUpdatesAsync") { (taskName: String) in
      try taskManager.unregisterTask(withName: taskName, consumerClass: EXLocationTaskConsumer.self)
    }

    AsyncFunction("hasStartedLocationUpdatesAsync") { (taskName: String) -> Bool in
      return try taskManager.task(withName: taskName, hasConsumerOf: EXLocationTaskConsumer.self)
    }

    // Geofencing

    AsyncFunction("startGeofencingAsync") { (taskName: String, options: [String: Any]) in
      try ensureBackgroundLocationPermissions(appContext)
      guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
        throw GeofencingUnavailableException()
      }

      try taskManager.registerTask(withName: taskName, consumer: EXGeofencingTaskConsumer.self, options: options)
    }

    AsyncFunction("stopGeofencingAsync") { (taskName: String) in
      try taskManager.unregisterTask(withName: taskName, consumerClass: EXGeofencingTaskConsumer.self)
    }

    AsyncFunction("hasStartedGeofencingAsync") { (taskName: String) -> Bool in
      return try taskManager.task(withName: taskName, hasConsumerOf: EXGeofencingTaskConsumer.self)
    }
  }
}
