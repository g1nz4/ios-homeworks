import Foundation

/// Доменная модель друга (обертка над User + инфо о дружбе).
struct Friend: Identifiable, Equatable {
    let id: String            // id друга
    let user: User            // профиль пользователя
    let friendshipId: String  // id записи дружбы
    let status: String        // статус дружбы
}

extension Friend {
    init(friendship: FriendshipDTO, profileDTO: UserProfileDTO) {
        self.init(
            id: profileDTO.id,
            user: User(from: profileDTO),
            friendshipId: friendship.id,
            status: friendship.status
        )
    }
}

/// DTO-сущность дружбы, как приходит с бэкенда.
struct FriendshipDTO: Codable {
    let id: String
    let userId: String
    let friendId: String
    let status: String
}

extension Friend {
    var name: String {
        user.name.displayName
    }
    
    var isOnline: Bool {
        user.isOnline ?? false
    }
    
    var birthday: Date? {
        user.birthDate
    }
}
