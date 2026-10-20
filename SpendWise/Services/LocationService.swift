//
//  LocationService.swift
//  SpendWise
//
//  Created by Theekshana on 2026-10-20.
//


import Foundation
import CoreLocation
internal import Combine

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = LocationService()

    private let locationManager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus

    private override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestCurrentLocation() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }

        locationManager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedWhenInUse ||
           authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        currentLocation = locations.last
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("Location error: \(error.localizedDescription)")
    }
}

