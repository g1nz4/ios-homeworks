import Foundation

protocol PlanetViewModelProtocol {
    var orbitalPeriod: Observable<String> { get }
    var isLoading: Observable<Bool> { get }

    func viewDidLoad()
}

final class PlanetViewModel: PlanetViewModelProtocol {
    
    let orbitalPeriod: Observable<String> = Observable("Загрузка данных...")
    let isLoading: Observable<Bool> = Observable(false)
    
    private let planetURL: String = "https://swapi.dev/api/planets/1"
    
    func viewDidLoad() {
        loadPlanet()
    }
    
    private func loadPlanet() {
        Task { [weak self] in
            await self?.requestPlanet()
        }
    }
    
    private func requestPlanet() async {
        guard let url = URL(string: planetURL) else {
            orbitalPeriod.value = NetworkError.invalidURL.rawValue
            return
        }
        
        isLoading.value = true

        defer {
            isLoading.value = false
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                orbitalPeriod.value = NetworkError.errorReceivingData.rawValue
            }
        
            let decoder = JSONDecoder()
            let planet = try decoder.decode(Planet.self, from: data)
            orbitalPeriod.value = "Период обращения планеты \(planet.name) вокруг своей звезды: \(planet.orbitalPeriod)"
        } catch {
            orbitalPeriod.value = "Ошибка: \(error.localizedDescription)"
        }
    }
}
