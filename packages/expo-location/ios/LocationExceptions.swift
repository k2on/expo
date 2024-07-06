// Copyright 2023-present 650 Industries. All rights reserved.

import ExpoModulesCore

internal final class LocationUnavailableException: Exception {
  override var reason: String {
    "Cannot obtain current location"
  }
}

internal final class GeocodingNetworkException: Exception {
  override var reason: String {
    "Geocoding rate limit exceeded - too many requests"
  }
}

internal final class GeocodingFailedException: Exception {
  override var reason: String {
    "Error while geocoding a location"
  }
}

internal final class TaskManagerUnavailableException: Exception {
  override var reason: String {
    "'expo-task-manager' module is required to use background services"
  }
}

internal final class LocationUpdatesUnavailableException: Exception {
  override var reason: String {
    "Background location has not been configured, make sure to add 'location' to 'UIBackgroundModes' in the Info.plist file"
  }
}

internal final class GeofencingUnavailableException: Exception {
  override var reason: String {
    "Geofencing is not available"
  }
}

internal final class LocationServicesDisabledException: Exception {
  override var reason: String {
    "Location services are disabled"
  }
}

internal final class DeniedForegroundLocationPermissionException: Exception {
  override var reason: String {
    "Location permission is required to do this operation"
  }
}

internal final class DeniedBackgroundLocationPermissionException: Exception {
  override var reason: String {
    "Background location permission is required to do this operation"
  }
}
