import Foundation

/// Данные для экрана подробной информации профиля.
struct ProfileInfoViewData {
    let status: String?
    let nickname: String?
    let about: String?
    let birthday: String?
    let city: String?
    let subscribersCount: String?
    let friendsCount: String?
    let followingCount: String?  
}

final class ProfileInfoViewModel {
    /// Готовые к показу данные.
    let data: ProfileInfoViewData

    init(user: User) {
        data = ProfileInfoViewData(
            status: user.status,
            nickname: user.nickname,
            about: user.about,
            birthday: Self.formatBirthday(user.birthDate),
            city: user.city,
            subscribersCount: user.subscribersCount.map { "\($0) подписчиков" },
            friendsCount: user.friendsCount.map { "\($0)" },
            followingCount: user.followingCount.map { "\($0)" },
        )
    }
    
    /// Форматирование даты рождения
    private static func formatBirthday(_ date: Date?) -> String? {
        guard let date else { return nil }
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateStyle = .long    
        return df.string(from: date)
    }
}
