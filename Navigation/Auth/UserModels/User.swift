import Foundation
import UIKit

struct Name: Equatable {
    let firstName: String
    let lastName: String
    
    var displayName: String {
        "\(firstName) \(lastName)"
    }
}

final class User: Identifiable, Equatable {
    
    let id: String
    var nickname: String?
    var name: Name
    var email: String?
    var phone: String?
    var city: String?
    let birthDate: Date?
    var status: String?
    
    /// Ссылка на аватар на сервере (Supabase Storage)
    var avatarURL: URL?
    
    /// Локальный аватар, который юзер только что установил
    var localAvatarImage: UIImage?
    
    init(
        id: String,
        nickname: String? = nil,
        name: Name,
        email: String? = nil,
        phone: String? = nil,
        city: String? = nil,
        birthDate: Date? = nil,
        status: String? = nil,
        avatarURL: URL? = nil,
        localAvatarImage: UIImage? = nil
    ) {
        self.id = id
        self.nickname = nickname
        self.name = name
        self.email = email
        self.phone = phone
        self.city = city
        self.birthDate = birthDate
        self.status = status
        self.avatarURL = avatarURL
        self.localAvatarImage = localAvatarImage
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

extension User {
    convenience init(from dto: UserProfileDTO) {
        self.init(
            id: dto.id,
            nickname: nil,
            name: Name(
                firstName: dto.firstName,
                lastName: dto.lastName
            ),
            email: dto.email,
            phone: dto.phone,
            city: dto.city,
            birthDate: dto.birthDate,
            status: dto.status,
            avatarURL: dto.avatarURL
        )
    }
}

