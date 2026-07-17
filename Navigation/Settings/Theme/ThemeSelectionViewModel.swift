import Foundation

/// ViewModel  экрана выбора темы.
final class ThemeSelectionViewModel {

    /// Текущая выбранная тема.
    private(set) var currentTheme: AppTheme

    /// Колбэк наружу (в SettingsViewModel через координатор).
    var onThemeSelected: ((AppTheme) -> Void)?

    init(currentTheme: AppTheme) {
        self.currentTheme = currentTheme
    }

    /// Список всех поддерживаемых тем.
    var items: [AppTheme] {
        [.system, .light, .dark]
    }

    /// Обработка выбора темы по индексу.
    func didSelectTheme(at index: Int) {
        guard index < items.count else { return }
        let theme = items[index]
        currentTheme = theme
        onThemeSelected?(theme)
    }
}
