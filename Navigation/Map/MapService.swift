import Foundation
import CoreLocation
import MapKit

protocol MapServiceProtocol: AnyObject {
    var authorizationStatusDidChange: ((CLAuthorizationStatus) -> Void)? { get set }
    
    func requestAuthorization()
    func currentLocation() async throws -> CLLocation
    func buildRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) async throws -> MKRoute
}

enum MapServiceError: String, Error {
    case notAuthorized = "Доступ к геолокации ещё не запрошен."
    case denied = "Доступ к геолокации запрещён. Разрешите его в Настройках, чтобы показывать ваше местоположение."
    case restricted = "Доступ к геолокации ограничен на этом устройстве."
    case noRoutes = "Не удалось построить маршрут."
    case unknown = "Произошла неизвестная ошибка. Попробуйте ещё раз."
}

final class MapService: NSObject, MapServiceProtocol {
   
    private let locationManager: CLLocationManager
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined {
        didSet {
            authorizationStatusDidChange?(authorizationStatus)
        }
    }
    
    var authorizationStatusDidChange: ((CLAuthorizationStatus) -> Void)?
    
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func currentLocation() async throws -> CLLocation {
        let authStatus = locationManager.authorizationStatus
        
        switch authStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            throw MapServiceError.denied
        case .restricted:
            throw MapServiceError.restricted
        case .authorizedAlways, .authorizedWhenInUse:
            break
        @unknown default:
            throw MapServiceError.notAuthorized
        }
        
        if let last = locationManager.location {
            return last
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.locationManager.startUpdatingLocation()
        }
    }
    
    func buildRoute(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) async throws -> MKRoute {
        let fromPlacemark = MKPlacemark(coordinate: from)
        let toPlacemark = MKPlacemark(coordinate: to)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: fromPlacemark)
        request.destination = MKMapItem(placemark: toPlacemark)
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        
        return try await withCheckedThrowingContinuation { continuation in
            directions.calculate { responce, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let route = responce?.routes.first else {
                    continuation.resume(throwing: MapServiceError.noRoutes)
                    return
                }
                
                continuation.resume(returning: route)
            }
        }
    }
}

extension MapService: CLLocationManagerDelegate {
    
    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        authorizationStatus = status
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let last = locations.last else { return }
        
        locationManager.stopUpdatingLocation()
        locationContinuation?.resume(returning: last)
        locationContinuation = nil
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
}
