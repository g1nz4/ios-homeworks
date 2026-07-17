import Foundation

/// ViewModel  экрана выбора языка.
final class LanguageSelectionViewModel {

    /// Текущий выбранный язык.
    private(set) var currentLanguage: AppLanguage

    /// Все доступные языки приложения.
    let languages = AppLanguage.allCases

    /// Колбэк, который срабатывает при выборе языка (для SettingsViewModel/координатора).
    var onLanguageSelected: ((AppLanguage) -> Void)?

    init(currentLanguage: AppLanguage) {
        self.currentLanguage = currentLanguage
    }

    /// Количество элементов для отображения в таблице.
    var itemsCount: Int {
        languages.count
    }

    /// Заголовок для строки по индексу.
    func title(at index: Int) -> String {
        languages[index].title
    }

    /// Является ли язык по индексу текущим выбранным языком.
    func isSelected(at index: Int) -> Bool {
        languages[index] == currentLanguage
    }

    /// Обработка выбора языка по индексу.
    func didSelectItem(at index: Int) {
        let lang = languages[index]
        guard lang != currentLanguage else { return }

        LocalizationManager.shared.setLanguage(lang)
        currentLanguage = lang
        onLanguageSelected?(lang)
    }
}
