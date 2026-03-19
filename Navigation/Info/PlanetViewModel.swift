import Foundation

protocol ResidentsViewModelProtocol {
    var residentNames: Observable<[String]> { get }
    var isLoading: Observable<Bool> { get }
    var textError: Observable<String?> { get }
    
    func viewDidLoad()
}

final class ResidentsViewModel: ResidentsViewModelProtocol {
    
    let residentNames: Observable<[String]> = Observable([])
    let isLoading: Observable<Bool> = Observable(false)
    let textError: Observable<String?> = Observable(nil)
    
    private let planetURL: String = "https://swapi.dev/api/planets/1"
    private let decoder = JSONDecoder()
    
    func viewDidLoad() {
        loadResidents()
    }
    
    private func loadResidents() {
        isLoading.value = true
        textError.value = nil
        residentNames.value = []
        
        Task { [weak self] in
            await self?.requestResidents()
        }
    }
    
    private func requestResidents() async {
        guard let url = URL(string: planetURL) else {
            textError.value = NetworkError.invalidURL.rawValue
            return
        }
        
        defer { isLoading.value = false }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                textError.value = NetworkError.errorReceivingData.rawValue
            }
        
            let planet = try decoder.decode(Planet.self, from: data)
            let residents = try await requestResidentsNames(urlStrings: planet.residents)
            residentNames.value = residents
        } catch {
            textError.value = "Ошибка: \(error.localizedDescription)"
        }
    }
    
    private func requestResidentsNames(urlStrings: [String]) async throws -> [String] {
        var names: [String] = []
       
        for urlString in urlStrings {
            guard let url = URL(string: urlString) else { continue }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let resident = try decoder.decode(Resident.self, from: data)
                names.append(resident.name)
            } catch {
                continue
            }
        }
        return names
    }
}
