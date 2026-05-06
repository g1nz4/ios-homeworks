import Foundation
import MapKit

protocol MapViewModelProtocol: AnyObject {
    var onAnnotationsChanged: (([MKAnnotation]) -> Void)? { get set }
    var onRouteChanged: ((MKPolyline?) -> Void)? { get set }
    var onRegionChanged: ((MKCoordinateRegion) -> Void)? { get set }
    var onError: ((String, MapErrorType) -> Void)? { get set }
    
    func viewDidLoad()
    func userAddedPoint(at coordinate: CLLocationCoordinate2D)
    func buildRouteToExistingPoint(_ coordinate: CLLocationCoordinate2D)
    func clearUserPoints()
}

enum MapErrorType {
    case permission
    case routing
    case unknown
}

final class MapViewModel: MapViewModelProtocol {
    
    var onAnnotationsChanged: (([MKAnnotation]) -> Void)?
    var onRouteChanged: ((MKPolyline?) -> Void)?
    var onRegionChanged: ((MKCoordinateRegion) -> Void)?
    var onError: ((String, MapErrorType) -> Void)?
    
    private let service: MapServiceProtocol
    private var annotations: [MKAnnotation] = []
    private var currentRoute: MKPolyline?
    
    init(service: MapServiceProtocol = MapService()) {
        self.service = service
        self.service.requestAuthorization()
    }
    
    func viewDidLoad() {
        Task { [weak self] in
            await self?.currentUserLocation()
        }
    }
    
    func userAddedPoint(at coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Цель"
        annotations.append(annotation)
        onAnnotationsChanged?(annotations)
        
        Task { [weak self] in
            await self?.buildRoute(to: coordinate)
        }
    }
    
    func buildRouteToExistingPoint(_ coordinate: CLLocationCoordinate2D) {
        Task { [weak self] in
            await self?.buildRoute(to: coordinate)
        }
    }
    
    func clearUserPoints() {
        annotations.removeAll()
        onAnnotationsChanged?(annotations)
        currentRoute = nil
        onRouteChanged?(nil)
    }
    
    private func setupAuthorizationObserver() {
        service.authorizationStatusDidChange = { [weak self] status in
            self?.handleAuthorizationChange(status)
        }
    }
    
    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            Task { [weak self] in
                await self?.currentUserLocation()
            }
        case .denied:
            let (message, type) = mapError(MapServiceError.denied)
            onError?(message, type)
        case .restricted:
            let (message, type) = mapError(MapServiceError.restricted)
            onError?(message, type)
        case .notDetermined:
            break
        @unknown default:
            let (message, type) = mapError(MapServiceError.notAuthorized)
            onError?(message, type)
        }
    }
    
    private func currentUserLocation() async {
        do {
            let location = try await service.currentLocation()
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            onRegionChanged?(region)
        } catch {
            let (message, type) = mapError(error)
            onError?(message, type)
        }
    }
    
    private func buildRoute(to coordinate: CLLocationCoordinate2D) async {
        do {
            let userLocation = try await service.currentLocation()
            let route = try await service.buildRoute(
                from: userLocation.coordinate,
                to: coordinate
            )
            guard route.polyline.pointCount > 1 else {
                throw MapServiceError.noRoutes
            }
            currentRoute = route.polyline
            onRouteChanged?(route.polyline)
        } catch {
            let (message, type) = mapError(error)
            onError?(message, type)
        }
    }
    
    private func mapError(_ error: Error) -> (String, MapErrorType) {
        if let mapError = error as? MapServiceError {
            
            switch mapError {
            case .denied, .restricted, .notAuthorized:
                return (mapError.rawValue, .permission)
            case .noRoutes:
                return (mapError.rawValue, .routing)
            case .unknown:
                return (mapError.rawValue, .routing)
            }
        }
        
        if let urlError = error as? URLError {
            
            switch urlError.code {
            case .notConnectedToInternet:
                return ("Нет подключения к интернету. Маршрут не может быть построен.", .routing)
            case .timedOut:
                return ("Время ожидания истекло. Попробуйте ещё раз.", .routing)
            default:
                return ("Произошла сетевая ошибка. Попробуйте позже.", .routing)
            }
        }
        
        let nsError = error as NSError
        if nsError.domain == MKErrorDomain {
            
            switch nsError.code {
            case 2:
                return ("Для выбранной точки не найдено доступных пеших маршрутов.", .routing)
            default:
                return (MapServiceError.noRoutes.rawValue, .routing)
            }
        }
        
        return (MapServiceError.unknown.rawValue, .unknown)
    }
}
