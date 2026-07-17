import Foundation

/// ViewModel для экрана  меню.
@MainActor
final class MenuViewModel {

    /// Массив элементов меню
    private(set) var items: [MenuItem] = []
    /// Текущий пользователь
    private(set) var user: User

    var onItemsUpdated: (() -> Void)?
    var onUserChanged: ((User) -> Void)?

    var userName: String { user.name.displayName }

    var avatarURLString: String {
        user.avatarURL?.absoluteString ?? ""
    }

    private var userUpdateObserver: NSObjectProtocol?

    init(user: User) {
        self.user = user

        // Подписка на обновление текущего пользователя через NotificationCenter
        userUpdateObserver = NotificationCenter.default.addObserver(
            forName: .currentUserDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let updated = notification.userInfo?[CurrentUserUpdateKey.user] as? User
            else { return }

            Task { @MainActor [weak self] in
                guard let self else { return }
                guard updated.id == self.user.id else { return }

                self.user = updated
                self.onUserChanged?(updated)
            }
        }

        Task { await loadItems() }
    }

    deinit {
        if let observer = userUpdateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Имитация асинхронной загрузки пунктов меню
    private func loadItems() async {
        try? await Task.sleep(nanoseconds: 150_000_000)

        let loaded: [MenuItem] = [
            .friends,
            .photos,
            .music,
            .favorites,
            .storiesArchive,
            .settings,
            .logout
        ]

        self.items = loaded
        self.onItemsUpdated?()
    }

    /// Обновить данные текущего пользователя
    func updateUser(_ user: User) {
        self.user = user
        onUserChanged?(user)
    }

    /// Количество элементов меню
    var numberOfItems: Int { items.count }

    /// Безопасное получение элемента по индексу
    func item(at index: Int) -> MenuItem? {
        guard index < items.count else { return nil }
        return items[index]
    }
}
