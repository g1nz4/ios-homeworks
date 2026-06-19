import Foundation

/// DTO для таблицы public.profiles в Supabase.
struct UserProfileDTO: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let city: String?
    let phone: String?
    let birthDate: Date?
    let createdAt: String?
    let email: String?
    let status: String?
    let avatarURL: URL?
}

extension UserProfileDTO {
    init(from user: User) {
        self.id = user.id
        self.firstName = user.name.firstName
        self.lastName = user.name.lastName
        self.city = user.city
        self.phone = user.phone
        self.birthDate = user.birthDate
        self.createdAt = nil
        self.email = user.email
        self.status = user.status
        self.avatarURL = user.avatarURL
    }
    
    func toDomain() -> User {
        let name = Name(firstName: firstName, lastName: lastName)
        
        return User(
            id: id,
            nickname: nil,
            name: name,
            email: email,
            phone: phone,
            city: city,
            birthDate: birthDate,
            status: status,
            avatarURL: avatarURL
        )
    }
}
