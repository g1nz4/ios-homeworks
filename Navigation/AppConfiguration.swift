import Foundation

enum AppConfiguration: String, CaseIterable {
    case one = "https://swapi.dev/api/people/8"
    case two = "https://swapi.dev/api/starships/3"
    case three = "https://swapi.dev/api/planets/5"
    
    var url: URL? {
        URL(string: self.rawValue)
    }
}
