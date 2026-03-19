import Foundation

struct Planet: Decodable {
    let name: String
    let residents: [String]
}

struct Resident: Decodable {
    let name: String
}
