import Foundation

/// ViewModel экрана редактирования данных профиля.
@MainActor
final class ProfileEditViewModel {
    
    private(set) var user: User
    private let userService: UserServiceProtocol
    
    var status: String
    var nickname: String
    var city: String
    var birthDate: Date?
    var firstName: String
    var lastName: String
    var about: String
    
    /// Успешное сохранение - отдаем свежего пользователя.
    var onSaved: ((User) -> Void)?
    
    /// Ошибка сохранения/валидации.
    var onError: ((Error) -> Void)?
    
    /// Изменение состояния загрузки (true - идёт запрос).
    var onLoadingChange: ((Bool) -> Void)?
    
    /// Изменений нет - просто закрыть экран без запроса.
    var onNoChanges: (() -> Void)?
    
    
    init(user: User, userService: UserServiceProtocol) {
        self.user = user
        self.userService = userService
        
        status = user.status ?? ""
        nickname = user.nickname ?? ""
        city = user.city ?? ""
        birthDate = user.birthDate
        firstName = user.name.firstName
        lastName = user.name.lastName
        about = user.about ?? ""
    }
    
    /// Обработка нажатия "Сохранить". Формирует новый `User` из текущих UI‑значений.  Если он полностью совпадает со старым --> `onNoChanges`, иначе вызов `userService.updateProfile`.
    func didTapSave() {
        // Снимок "старого" пользователя
        let oldUser = user
        
        // Нормализованные значения из полей UI
        let normalizedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newNickname = nickname
        let newCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let newAbout = about
        let newStatus = status
        let newBirth = birthDate
        
        // Формирование обновлённого пользователя
        let updatedUser = User(
            id: oldUser.id,
            nickname: newNickname,
            name: Name(firstName: normalizedFirst, lastName: normalizedLast),
            gender: oldUser.gender,
            email: oldUser.email,
            phone: oldUser.phone,
            city: newCity,
            birthDate: newBirth,
            status: newStatus,
            about: newAbout,
            avatarURL: oldUser.avatarURL,
            coverURL: oldUser.coverURL,
            subscribersCount: oldUser.subscribersCount,
            friendsCount: oldUser.friendsCount,
            followingCount: oldUser.followingCount
        )
        
        // Если ничего не поменялось - закрыть экран
        guard updatedUser != oldUser else {
            AppLogger.debug("ProfileEdit: didTapSave — no changes, closing")
            onNoChanges?()
            return
        }
        
        // Есть изменения - отправить запрос
        onLoadingChange?(true)
        
        Task { [weak self] in
            guard let self else { return }
            do {
                let fresh = try await userService.updateProfile(user: updatedUser)
                self.user = fresh
                self.onLoadingChange?(false)
                
                NotificationCenter.default.post(
                    name: .currentUserDidUpdate,
                    object: nil,
                    userInfo: [CurrentUserUpdateKey.user: fresh]
                )
                self.onSaved?(fresh)
            } catch {
                self.onLoadingChange?(false)
                self.onError?(error)
            }
        }
    }
}
