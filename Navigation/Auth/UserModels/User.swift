import Foundation

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
    var birthDate: Date?
    var status: String?
    var about: String?
    var avatarURL: URL?
    var coverURL: URL? = nil
    var subscribersCount: Int?
    var friendsCount: Int?
    var followingCount: Int?
    
    init(
        id: String,
        nickname: String? = nil,
        name: Name,
        email: String? = nil,
        phone: String? = nil,
        city: String? = nil,
        birthDate: Date? = nil,
        status: String? = nil,
        about: String? = nil,
        avatarURL: URL? = nil,
        coverURL: URL? = nil,
        subscribersCount: Int? = nil,
        friendsCount: Int? = nil,
        followingCount: Int? = nil
    ) {
        self.id = id
        self.nickname = nickname
        self.name = name
        self.email = email
        self.phone = phone
        self.city = city
        self.birthDate = birthDate
        self.status = status
        self.about = about
        self.avatarURL = avatarURL
        self.coverURL = coverURL
        self.subscribersCount = subscribersCount
        self.friendsCount = friendsCount
        self.followingCount = followingCount
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id &&
        lhs.nickname == rhs.nickname &&
        lhs.name == rhs.name &&
        lhs.email == rhs.email &&
        lhs.phone == rhs.phone &&
        lhs.city == rhs.city &&
        lhs.birthDate == rhs.birthDate &&
        lhs.status == rhs.status &&
        lhs.about == rhs.about &&
        lhs.avatarURL == rhs.avatarURL &&
        lhs.coverURL == rhs.coverURL &&
        lhs.subscribersCount == rhs.subscribersCount &&
        lhs.friendsCount == rhs.friendsCount &&
        lhs.followingCount == rhs.followingCount
    }
}

extension User {
    convenience init(from dto: UserProfileDTO) {
        
        let avatarURL = dto.avatarUrl.flatMap { URL(string: $0) }
        let coverURL  = dto.coverUrl.flatMap { URL(string: $0) }
        
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
            about: dto.about,
            avatarURL: avatarURL,
            coverURL: coverURL,
            subscribersCount: dto.subscribersCount,
            friendsCount: dto.friendsCount,
            followingCount: dto.followingCount
        )
    }
}

