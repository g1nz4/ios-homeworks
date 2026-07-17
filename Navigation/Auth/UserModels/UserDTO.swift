import Foundation

/// DTO для таблицы public.profiles в Supabase.
struct UserProfileDTO: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let gender: String
    let city: String?
    let phone: String?
    let nickname: String?
    let birthDate: Date?
    let createdAt: String?
    let email: String?
    let status: String?
    let about: String?
    let avatarUrl: String?
    let coverUrl: String?
    let subscribersCount: Int?
    let friendsCount: Int?
    let followingCount: Int?
    let isOnline: Bool
    
}

extension UserProfileDTO {
    init(from user: User) {
        self.id = user.id
        self.firstName = user.name.firstName
        self.lastName = user.name.lastName
        self.gender = user.gender.apiValue
        self.city = user.city
        self.phone = user.phone
        self.nickname = user.nickname
        self.birthDate = user.birthDate
        self.createdAt = nil
        self.email = user.email
        self.status = user.status
        self.about = user.about
        self.avatarUrl = user.avatarURL?.absoluteString
        self.coverUrl  = user.coverURL?.absoluteString
        self.subscribersCount = user.subscribersCount
        self.friendsCount = user.friendsCount
        self.followingCount = user.followingCount
        self.isOnline = user.isOnline ?? false
        
    }
    
    func toDomain() -> User {
        let name = Name(firstName: firstName, lastName: lastName)
               
       let avatarURL = avatarUrl.flatMap { URL(string: $0) }
       let coverURL  = coverUrl.flatMap { URL(string: $0) }
       let genderEnum = Gender(apiValue: gender)
        
       return User(
           id: id,
           nickname: nickname,
           name: name,
           gender: genderEnum,
           email: email,
           phone: phone,
           city: city,
           birthDate: birthDate,
           status: status,
           about: about,
           avatarURL: avatarURL,
           coverURL: coverURL,
           subscribersCount: subscribersCount,
           friendsCount: friendsCount,
           followingCount: followingCount,
           isOnline: isOnline
       )
        
    }
}
