import UIKit
import MapKit

final class MapViewController: UIViewController {
    
    private let viewModel: MapViewModelProtocol
    
    private lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.delegate = self
        map.showsUserLocation = true
        
        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(mapLongPressed(_:))
        )
        longPress.minimumPressDuration = 1.0
        map.addGestureRecognizer(longPress)
        
        return map
    }()
    
    init(viewModel: MapViewModelProtocol = MapViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupConstraint()
        configureMapAppearance()
        bindingViewModel()
        viewModel.viewDidLoad()
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trash.circle"),
            style: .plain,
            target: self,
            action: #selector(clearTapped)
        )
    }
    
    private func setupConstraint() {
        view.addSubview(mapView)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureMapAppearance() {
        mapView.mapType = .mutedStandard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsTraffic = true
    }
    
    private func bindingViewModel() {
        viewModel.onAnnotationsChanged = { [weak self] annotations in
            guard let self else { return }
           
            let toRemove = self.mapView.annotations.filter { !($0 is MKUserLocation) }
            self.mapView.removeAnnotations(toRemove)
            self.mapView.addAnnotations(annotations)
        }

        viewModel.onRouteChanged = { [weak self] polyline in
            guard let self else { return }
           
            self.mapView.removeOverlays(self.mapView.overlays)
           
            if let polyline = polyline {
                self.mapView.addOverlay(polyline)
                self.mapView.setVisibleMapRect(
                    polyline.boundingMapRect,
                    edgePadding: UIEdgeInsets(
                        top: 40,
                        left: 40,
                        bottom: 40,
                        right: 40
                    ),
                    animated: true
                )
            }
        }

        viewModel.onRegionChanged = { [weak self] region in
            self?.mapView.setRegion(region, animated: true)
        }

        viewModel.onError = { [weak self] message, type in
            switch type {
            case .permission:
                self?.showPermissionAlert(message: message)
            case .routing, .unknown:
                self?.showSimpleErrorAlert(message: message)
            }
        }
    }
    
    private func showPermissionAlert(message: String) {
        if presentedViewController is UIAlertController { return }

        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Настройки", style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString),
                  UIApplication.shared.canOpenURL(url) else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })

        present(alert, animated: true)
    }
    
    private func showSimpleErrorAlert(message: String) {
        if presentedViewController is UIAlertController { return }

        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
       
        present(alert, animated: true)
    }
    
    @objc private func mapLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let point = gesture.location(in: mapView)
        let coord = mapView.convert(point, toCoordinateFrom: mapView)

        viewModel.userAddedPoint(at: coord)
    }

    @objc private func clearTapped() {
        viewModel.clearUserPoints()
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(
        _ mapView: MKMapView,
        rendererFor overlay: MKOverlay
    ) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }
        
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = .systemGreen
        renderer.lineWidth = 4
       
        return renderer
    }
    
    func mapView(
        _ mapView: MKMapView,
        didSelect view: MKAnnotationView
    ) {
        guard let annotation = view.annotation,
                !(annotation is MKUserLocation) else { return }

        let coordinate = annotation.coordinate
        viewModel.buildRouteToExistingPoint(coordinate)
    }
}
