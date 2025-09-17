//
//  LocationContextProvider.swift
//  SpecificationKit
//
//  Created by SpecificationKit on 2024.
//

#if canImport(CoreLocation) && !os(tvOS)
    import Foundation
    import CoreLocation
    #if canImport(Combine)
        import Combine
    #endif

    /// A context provider that provides location-based data for specifications on Apple platforms that support Core Location (excluding tvOS).
    ///
    /// `LocationContextProvider` integrates with CoreLocation to provide real-time location data
    /// for specification evaluation. It handles permission requests, location updates, and provides
    /// graceful fallbacks when location services are unavailable.
    ///
    /// ## Key Features
    ///
    /// - **Automatic Permission Handling**: Requests location permissions when needed
    /// - **Configurable Accuracy**: Supports various location accuracy levels
    /// - **Battery Optimization**: Configurable distance filter to minimize battery usage
    /// - **Fallback Support**: Optional fallback location when services are unavailable
    /// - **Reactive Updates**: Publishes location changes via Combine when available
    /// - **Thread-Safe**: All operations are thread-safe for concurrent access
    ///
    /// ## Usage Examples
    ///
    /// ### Basic Location Provider
    /// ```swift
    /// let locationProvider = LocationContextProvider()
    ///
    /// // Use with location-based specifications
    /// struct NearbyStoreSpec: Specification {
    ///     let storeLocation: CLLocationCoordinate2D
    ///     let radius: CLLocationDistance
    ///
    ///     func isSatisfiedBy(_ context: LocationContext) -> Bool {
    ///         guard let userLocation = context.currentLocation else { return false }
    ///         let storeLocation = CLLocation(latitude: storeLocation.latitude, longitude: storeLocation.longitude)
    ///         return userLocation.distance(from: storeLocation) <= radius
    ///     }
    /// }
    ///
    /// @Satisfies(provider: locationProvider, using: NearbyStoreSpec(storeLocation: storeCoord, radius: 1000))
    /// var isNearStore: Bool
    /// ```
    ///
    /// ### Custom Configuration
    /// ```swift
    /// let config = LocationContextProvider.Configuration(
    ///     accuracy: kCLLocationAccuracyNearestTenMeters,
    ///     distanceFilter: 50.0, // Update every 50 meters
    ///     requestPermission: true,
    ///     fallbackLocation: CLLocation(latitude: 37.7749, longitude: -122.4194) // SF default
    /// )
    ///
    /// let locationProvider = LocationContextProvider(configuration: config)
    /// ```
    ///
    /// ### Privacy-Conscious Usage
    /// ```swift
    /// let config = LocationContextProvider.Configuration(
    ///     accuracy: kCLLocationAccuracyReduced, // iOS 14+ reduced accuracy
    ///     distanceFilter: 100.0,
    ///     requestPermission: false, // Don't auto-request, let app handle it
    ///     fallbackLocation: nil
    /// )
    ///
    /// let locationProvider = LocationContextProvider(configuration: config)
    /// ```
    ///
    /// ### SwiftUI Integration
    /// ```swift
    /// struct LocationAwareView: View {
    ///     @ObservedSatisfies(
    ///         provider: locationProvider,
    ///         using: GeofenceSpec(center: targetLocation, radius: 500)
    ///     )
    ///     var isInTargetArea: Bool
    ///
    ///     var body: some View {
    ///         VStack {
    ///             if isInTargetArea {
    ///                 Text("Welcome! You're in the target area.")
    ///                     .foregroundColor(.green)
    ///             } else {
    ///                 Text("Move closer to the target location.")
    ///                     .foregroundColor(.orange)
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Location Context Structure
    ///
    /// The `LocationContext` provides comprehensive location data:
    /// - `currentLocation`: The latest CLLocation reading
    /// - `latitude`/`longitude`: Coordinate components
    /// - `accuracy`: Horizontal accuracy in meters
    /// - `timestamp`: When the location was captured
    /// - `altitude`: Elevation above sea level
    /// - `speed`: Current speed in m/s
    /// - `course`: Direction of travel in degrees
    ///
    /// ## Privacy Considerations
    ///
    /// This provider respects user privacy and platform guidelines:
    /// - Only requests permissions when explicitly configured to do so
    /// - Supports reduced accuracy mode (iOS 14+)
    /// - Provides clear fallback mechanisms when location is unavailable
    /// - Stops location updates appropriately to preserve battery
    @available(iOS 14.0, watchOS 7.0, macOS 11.0, macCatalyst 14.0, *)
    public final class LocationContextProvider: NSObject, ContextProviding {

        // MARK: - Configuration

        /// Configuration options for the location context provider
        public struct Configuration {
            /// The desired accuracy of location readings
            public let accuracy: CLLocationAccuracy

            /// The minimum distance (in meters) that must be traveled before location updates
            public let distanceFilter: CLLocationDistance

            /// Whether to automatically request location permissions
            public let requestPermission: Bool

            /// A fallback location to use when location services are unavailable
            public let fallbackLocation: CLLocation?

            /// Default configuration with balanced accuracy and battery usage
            public static let `default` = Configuration(
                accuracy: kCLLocationAccuracyBest,
                distanceFilter: 10.0,
                requestPermission: true,
                fallbackLocation: nil
            )

            /// Battery-optimized configuration for background usage
            public static let batteryOptimized = Configuration(
                accuracy: kCLLocationAccuracyHundredMeters,
                distanceFilter: 100.0,
                requestPermission: true,
                fallbackLocation: nil
            )

            /// High-precision configuration for navigation or precise location needs
            public static let highPrecision = Configuration(
                accuracy: kCLLocationAccuracyBestForNavigation,
                distanceFilter: 5.0,
                requestPermission: true,
                fallbackLocation: nil
            )

            #if os(iOS)
                /// Privacy-conscious configuration with reduced accuracy (iOS 14+)
                @available(iOS 14.0, *)
                public static let privacyFocused = Configuration(
                    accuracy: kCLLocationAccuracyReduced,
                    distanceFilter: 50.0,
                    requestPermission: false,
                    fallbackLocation: nil
                )

            #endif

            /// Creates a custom configuration
            public init(
                accuracy: CLLocationAccuracy,
                distanceFilter: CLLocationDistance,
                requestPermission: Bool,
                fallbackLocation: CLLocation?
            ) {
                self.accuracy = accuracy
                self.distanceFilter = distanceFilter
                self.requestPermission = requestPermission
                self.fallbackLocation = fallbackLocation
            }
        }

        // MARK: - Context Type

        /// The context type provided by this provider
        public struct LocationContext {
            /// The current location reading
            public let currentLocation: CLLocation?

            /// Quick access to latitude
            public var latitude: Double? { currentLocation?.coordinate.latitude }

            /// Quick access to longitude
            public var longitude: Double? { currentLocation?.coordinate.longitude }

            /// Location accuracy in meters
            public var accuracy: CLLocationAccuracy? { currentLocation?.horizontalAccuracy }

            /// When the location was captured
            public var timestamp: Date? { currentLocation?.timestamp }

            /// Altitude above sea level in meters
            public var altitude: CLLocationDistance? { currentLocation?.altitude }

            /// Current speed in meters per second
            public var speed: CLLocationSpeed? { currentLocation?.speed }

            /// Direction of travel in degrees (0-359.9)
            public var course: CLLocationDirection? { currentLocation?.course }

            internal init(currentLocation: CLLocation?) {
                self.currentLocation = currentLocation
            }
        }

        // MARK: - Private Properties

        private let configuration: Configuration
        private let locationManager: CLLocationManager
        private var currentLocation: CLLocation?
        private let lock = NSLock()

        #if canImport(Combine)
            private let locationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
            public let objectWillChange = PassthroughSubject<Void, Never>()
        #endif

        // MARK: - Initialization

        /// Creates a new location context provider with the specified configuration
        /// - Parameter configuration: The configuration to use for location services
        public init(configuration: Configuration = .default) {
            self.configuration = configuration
            self.locationManager = CLLocationManager()

            super.init()

            setupLocationManager()

            if configuration.requestPermission {
                requestLocationPermission()
            }
        }

        // MARK: - ContextProviding

        public func currentContext() -> LocationContext {
            lock.lock()
            defer { lock.unlock() }
            return LocationContext(currentLocation: currentLocation)
        }

        // MARK: - Location Manager Setup

        private func setupLocationManager() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = configuration.accuracy
            locationManager.distanceFilter = configuration.distanceFilter
        }

        private func requestLocationPermission() {
            #if os(macOS)
                switch locationManager.authorizationStatus {
                case .notDetermined:
                    locationManager.requestWhenInUseAuthorization()
                case .denied, .restricted:
                    handleLocationUnavailable()
                case .authorizedAlways:
                    startLocationUpdates()
                @unknown default:
                    handleLocationUnavailable()
                }
            #else
                switch locationManager.authorizationStatus {
                case .notDetermined:
                    locationManager.requestWhenInUseAuthorization()
                case .denied, .restricted:
                    // Use fallback location if available
                    handleLocationUnavailable()
                case .authorizedWhenInUse, .authorizedAlways:
                    startLocationUpdates()
                @unknown default:
                    handleLocationUnavailable()
                }
            #endif
        }

        private func startLocationUpdates() {
            guard CLLocationManager.locationServicesEnabled() else {
                handleLocationUnavailable()
                return
            }
            locationManager.startUpdatingLocation()
        }

        private func handleLocationUnavailable() {
            lock.lock()
            defer { lock.unlock() }

            currentLocation = configuration.fallbackLocation

            #if canImport(Combine)
                locationSubject.send(currentLocation)
                objectWillChange.send()
            #endif
        }

        // MARK: - Public Control Methods

        /// Manually start location updates (if permissions allow)
        public func startUpdates() {
            requestLocationPermission()
        }

        /// Stop location updates to preserve battery
        public func stopUpdates() {
            locationManager.stopUpdatingLocation()
        }

        /// Request a one-time location update
        public func requestLocation() {
            guard CLLocationManager.locationServicesEnabled() else {
                handleLocationUnavailable()
                return
            }
            locationManager.requestLocation()
        }

        /// Check if location services are available and authorized
        public var isLocationAvailable: Bool {
            guard CLLocationManager.locationServicesEnabled() else {
                return false
            }

            #if os(macOS)
                return locationManager.authorizationStatus == .authorizedAlways
            #else
                let status = locationManager.authorizationStatus
                return status == .authorizedWhenInUse || status == .authorizedAlways
            #endif
        }

        /// Get the current authorization status
        public var authorizationStatus: CLAuthorizationStatus {
            return locationManager.authorizationStatus
        }
    }

    // MARK: - CLLocationManagerDelegate

    @available(iOS 14.0, watchOS 7.0, macOS 11.0, macCatalyst 14.0, *)
    extension LocationContextProvider: CLLocationManagerDelegate {

        public func locationManager(
            _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
        ) {
            guard let location = locations.last else { return }

            lock.lock()
            defer { lock.unlock() }

            currentLocation = location

            #if canImport(Combine)
                locationSubject.send(location)
                objectWillChange.send()
            #endif
        }

        public func locationManager(
            _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
        ) {
            #if os(macOS)
                switch status {
                case .authorizedAlways:
                    startLocationUpdates()
                case .denied, .restricted:
                    handleLocationUnavailable()
                case .notDetermined:
                    if configuration.requestPermission {
                        manager.requestWhenInUseAuthorization()
                    }
                @unknown default:
                    handleLocationUnavailable()
                }
            #else
                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    startLocationUpdates()
                case .denied, .restricted:
                    handleLocationUnavailable()
                case .notDetermined:
                    if configuration.requestPermission {
                        manager.requestWhenInUseAuthorization()
                    }
                @unknown default:
                    handleLocationUnavailable()
                }
            #endif
        }

        public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("LocationContextProvider failed with error: \(error.localizedDescription)")
            handleLocationUnavailable()
        }
    }

    // MARK: - Combine Support

    #if canImport(Combine)
        @available(iOS 14.0, watchOS 7.0, macOS 11.0, macCatalyst 14.0, *)
        extension LocationContextProvider: ContextUpdatesProviding {

            /// Publisher that emits whenever the location context may have changed
            public var contextUpdates: AnyPublisher<Void, Never> {
                objectWillChange.eraseToAnyPublisher()
            }

            /// Async stream of context updates
            public var contextStream: AsyncStream<Void> {
                AsyncStream { continuation in
                    let subscription = objectWillChange.sink { _ in
                        continuation.yield(())
                    }
                    continuation.onTermination = { _ in
                        _ = subscription
                    }
                }
            }

            /// Publisher that emits location updates
            public var locationUpdates: AnyPublisher<CLLocation?, Never> {
                locationSubject.eraseToAnyPublisher()
            }
        }
    #endif

    // MARK: - Convenience Extensions

    @available(iOS 14.0, watchOS 7.0, macOS 11.0, macCatalyst 14.0, *)
    extension LocationContextProvider {

        /// Creates a specification that evaluates based on distance from a point
        /// - Parameters:
        ///   - center: The center coordinate to measure distance from
        ///   - maxDistance: The maximum distance in meters
        /// - Returns: A specification that checks if current location is within the distance
        public func proximitySpecification(
            center: CLLocationCoordinate2D,
            maxDistance: CLLocationDistance
        ) -> AnySpecification<Any> {
            AnySpecification { _ in
                let context = self.currentContext()
                guard let currentLocation = context.currentLocation else { return false }

                let centerLocation = CLLocation(
                    latitude: center.latitude, longitude: center.longitude)
                let distance = currentLocation.distance(from: centerLocation)

                return distance <= maxDistance
            }
        }

        /// Creates a specification that evaluates based on being within a geographic region
        /// - Parameter region: The CLRegion to check against
        /// - Returns: A specification that checks if current location is within the region
        public func regionSpecification(region: CLRegion) -> AnySpecification<Any> {
            AnySpecification { _ in
                let context = self.currentContext()
                guard let currentLocation = context.currentLocation else { return false }

                if let circularRegion = region as? CLCircularRegion {
                    let centerLocation = CLLocation(
                        latitude: circularRegion.center.latitude,
                        longitude: circularRegion.center.longitude
                    )
                    let distance = currentLocation.distance(from: centerLocation)
                    return distance <= circularRegion.radius
                }

                #if os(watchOS) || os(macOS)
                return region.contains(currentLocation.coordinate)
                #else
                // CLRegion.contains(_:) remains unavailable on iOS, so we cannot evaluate non-circular regions.
                return false
                #endif
            }
        }

        #if os(iOS) || os(macOS)
        /// Creates a specification that evaluates using a modern geographic condition on supported platforms
        /// - Parameter condition: The `CLCircularGeographicCondition` to check against (iOS 17+, macOS 14+)
        /// - Returns: A specification that checks if the current location satisfies the condition
        @available(iOS 17.0, macOS 14.0, macCatalyst 17.0, *)
        public func geographicConditionSpecification(condition: CLMonitor.CircularGeographicCondition) -> AnySpecification<Any> {
            AnySpecification { _ in
                let context = self.currentContext()
                guard let currentLocation = context.currentLocation else { return false }
                let centerLocation = CLLocation(
                    latitude: condition.center.latitude,
                    longitude: condition.center.longitude
                )
                let distance = currentLocation.distance(from: centerLocation)
                return distance <= condition.radius
            }
        }
        #endif
    }

#endif

