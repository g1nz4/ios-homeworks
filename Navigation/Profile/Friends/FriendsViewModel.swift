import Foundation

/// Вкладки в UI: "Все" и "Онлайн".
/// rawValue используется для биндинга с индексом сегмент‑контрола / вкладки
enum Tab: Int, CaseIterable {
    case all
    case online
}

/// Единица отображения друга в UI.
struct FriendItem: Hashable {
    let id: String              // id пользователя
    let avatarPath: String?     // путь/URL к аватару
    let displayName: String     // отображаемое имя
    let city: String?           // город (может отсутствовать)
    let birthday: Date?         // дата рождения (может отсутствовать)
    let isOnline: Bool          // флаг "в сети" сейчас
}

/// Состояние всего экрана.
/// Хранит как текущие фильтры/сортировки, так и итоговый список друзей.
struct FriendsViewModelState: Equatable {
    /// Итоговый список после применения выбранной вкладки, поиска и сортировки.
    var friends: [FriendItem] = []
    
    /// Текущий текст в поисковой строке.
    var searchText: String = ""
    
    /// Активная вкладка (все / онлайн).
    var selectedTab: Tab = .all
    
    /// Текущий тип сортировки.
    var selectedSort: FriendsViewModel.Sort = .name
    
    /// Общее количество друзей (без фильтров).
    var allFriendsCount: Int = 0
    
    /// Количество друзей онлайн (без учёта поиска и вкладки).
    var onlineFriendsCount: Int = 0
    
    /// Флаг загрузки: true, пока идёт запрос к бэку.
    var isLoading: Bool = false
    
    /// Сообщение об ошибке (если последняя загрузка упала).
    var errorMessage: String? = nil
}


@MainActor
protocol FriendsViewModelOutput: AnyObject {
    func didUpdateState(_ state: FriendsViewModelState)
}

/// Основная ViewModel для экрана списка друзей.
@MainActor
final class FriendsViewModel {
 
    weak var output: FriendsViewModelOutput?
    
    /// Варианты сортировки списка друзей
    enum Sort: CaseIterable {
        case name       // сортировка по имени (по алфавиту)
        case birthday   // сортировка по дню рождения (месяц + день)
        
        /// Текст в action sheet (кнопка выбора сортировки).
        var title: String {
            switch self {
            case .name:
                return "По алфавиту"
            case .birthday:
                return "По дню рождения"
            }
        }
        
        /// Текст в строке "Сортировка: …" .
        var rowTitle: String {
            switch self {
            case .name:     return "по алфавиту"
            case .birthday: return "по дню рождения"
            }
        }
    }
    
    /// Текущее состояние экрана.
    private(set) var state = FriendsViewModelState() {
        didSet { output?.didUpdateState(state) }
    }
    
    /// Список друзей, как пришёл с бэка.
    private var allFriends: [FriendItem] = []
    
    /// Сервис для работы с пользователями.
    private let userService: UserServiceProtocol
    
    /// Текущий авторизованный пользователь.
    private let currentUser: User
    
    init(
        userService: UserServiceProtocol,
        currentUser: User
    ) {
        self.userService = userService
        self.currentUser = currentUser
    }
    
    func viewDidLoad() async {
        await load()
    }
    
    /// Обработка изменения текста поиска.
    func didChangeSearchText(_ text: String) {
        state.searchText = text
        applyFiltersAndSorting()
    }
    
    /// Обработка переключения вкладок.
    func didSelectTab(index: Int) {
        guard let tab = Tab(rawValue: index) else { return }
        state.selectedTab = tab
        applyFiltersAndSorting()
    }
    
    /// Обработка выбора типа сортировки из action sheet / меню.
    func didSelectSort(_ sort: Sort) {
        guard sort != state.selectedSort else { return }
        state.selectedSort = sort
        applyFiltersAndSorting()
    }
    
    /// Полная перезагрузка списка друзей с бэкенда.
    func load() async {
        state.isLoading = true
        state.errorMessage = nil
        
        do {
            // Запрос списока друзей текущего пользователя
            let users = try await userService.fetchFriends(for: currentUser.id)
            
            // Маппинг в доменную модель User в FriendItem
            let mapped: [FriendItem] = users.map { user in
                FriendItem(
                    id: user.id,
                    avatarPath: user.avatarURL?.absoluteString,
                    displayName: user.name.displayName,
                    city: user.city,
                    birthday: user.birthDate,
                    isOnline: user.isOnline ?? false
                )
            }
            
            // Сохранение "сырыех" данных для последующей фильтрации
            allFriends = mapped
            
            // Обновление счётчикок (все / онлайн) без учёта текущих фильтров
            state.allFriendsCount = mapped.count
            state.onlineFriendsCount = mapped.filter { $0.isOnline }.count
            
            // Применение выбранных фильтров (вкладка, поиск, сортировка) к только что загруженным данным.
            applyFiltersAndSorting()
        } catch {
            // Здесь пока логирование ошибки
            AppLogger.error("fetchFriends error: \(error)")
            state.errorMessage = error.localizedDescription
        }
        
        // В любом случае (успех/ошибка) снять индикатор загрузки
        state.isLoading = false
    }
    
    /// Применение текущих выбранных фильтров и сортировки к allFriends и запись результата в state.friends
    private func applyFiltersAndSorting() {
   
        var result: [FriendItem] = allFriends
        
        // Фильтр по вкладке: если выбрана .online — оставить только онлайн
        if state.selectedTab == .online {
            result = result.filter { $0.isOnline }
        }
        
        // Фильтр по строке поиска (по имени)
        let query = state.searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !query.isEmpty {
            result = result.filter {
                $0.displayName.localizedCaseInsensitiveContains(query)
            }
        }
       
        // Сортировка по выбранному типу
        switch state.selectedSort {
        case .name:
            result.sort {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
            
        case .birthday:
            // Для сортировки по дню рождения только месяц и день
            let calendar = Calendar.current
            
            // Вспомогательная функция, которая достаёт (месяц, день) из даты рождения. Если даты нет — возвращает nil.
            func monthDay(_ date: Date?) -> (Int, Int)? {
                guard let date else { return nil }
                let comps = calendar.dateComponents([.month, .day], from: date)
                guard let m = comps.month, let d = comps.day else { return nil }
                return (m, d)
            }
            
            result.sort { lhs, rhs in
                switch (monthDay(lhs.birthday), monthDay(rhs.birthday)) {
                
                case let (l?, r?):
                    if l.0 != r.0 { return l.0 < r.0 }
                    if l.1 != r.1 { return l.1 < r.1 }
                    return lhs.displayName < rhs.displayName
                
                case (nil, .some):  return false
                
                case (.some, nil):  return true
                
                case (nil, nil):    return lhs.displayName < rhs.displayName
                }
            }
        }
        
        // Обновить итоговый список в состоянии
        state.friends = result
    }
    
    /// Форматтер для отображения дня рождения ("5 июл").
    private lazy var birthdayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale.current
        df.setLocalizedDateFormatFromTemplate("d MMM")
        return df
    }()
    
    // Текст под основным заголовком ячейки друга.
    func subtitleText(for item: FriendItem) -> String? {
        switch state.selectedSort {
        case .name:
            // Если город не пустой — показать его, иначе ничего
            return item.city?.isEmpty == false ? item.city : nil
            
        case .birthday:
            // Если есть дата рождения — форматирование её в строку
            guard let date = item.birthday else { return nil }
            return birthdayFormatter.string(from: date)
        }
    }
    
    func birthdayText(for item: FriendItem) -> String? {
        guard let date = item.birthday else { return nil }
        return birthdayFormatter.string(from: date)
    }
}
