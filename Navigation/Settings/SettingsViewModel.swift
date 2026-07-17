import Foundation
import UserNotifications

/// То что VM сообщает контроллеру
struct SettingsViewModelOutputs {
    /// Данные для таблицы настроек изменились.
    var onDataChanged: (([SettingsSectionViewData]) -> Void)?
    
    /// Открыть системные настройки iOS для конкретного разрешения (уведомления, камера и т.д.).
    var onOpenSystemSettings: ((PermissionKind) -> Void)?
    
    /// Тема приложения изменилась.
    var onThemeChanged: ((AppTheme) -> Void)?
    
    /// Показать алерт о том, что доступ к какому‑то ресурсу запрещён.
    var onPermissionDeniedAlert: ((PermissionKind) -> Void)?
    
    /// Открыть экран выбора темы.
    var onOpenThemeSelection: (() -> Void)?
    
    /// Открыть экран выбора языка.
    var onOpenLanguageSelection: (() -> Void)?
    
    /// Язык приложения изменился.
    var onLanguageChanged: ((AppLanguage) -> Void)?
    
    /// Пользователь включил/выключил свайп между вкладками.
    var onTabSwipeChanged: ((Bool) -> Void)?
}

/// ViewModel экрана настроек.
///
/// Отвечает за:
/// 1. чтение и сохранение настроек пользователя (`UserSettingsStorage`)
/// 2. запрос и актуализацию системных разрешений (`PermissionService`, `UNUserNotificationCenter`)
/// 3. построение view‑моделей секций/строк для таблицы
/// 4. эмит событий наружу через `SettingsViewModelOutputs`
@MainActor
final class SettingsViewModel {
    
    /// Хранилище пользовательских настроек.
    private let settingsStorage: UserSettingsStorage
    
    /// Сервис работы с локальными уведомлениями.
    private let notificationsService: LocalNotificationsService
    
    /// Сервис работы с системными разрешениями.
    private let permissionService: PermissionService
    
    /// Фактический статус разрешения на уведомления от системы.
    private var notificationsGranted: Bool = false
    
    /// Текущий статус разрешения на камеру, полученный из `PermissionService`.
    private var cameraStatus: PermissionService.PermissionResult = .unavailable
    
    /// Текущий статус разрешения на доступ к фото, полученный из `PermissionService`.
    private var photoStatus: PermissionService.PermissionResult = .unavailable
    
    /// Текущая тема приложения (из хранилища настроек).
    var currentTheme: AppTheme {
        settingsStorage.appTheme
    }
    
    /// Текущий язык приложения (из хранилища настроек).
    var currentLanguage: AppLanguage {
        settingsStorage.appLanguage
    }
    
    /// Набор коллбэков, через которые VM общается с внешним миром. Контроллер/координатор подписывается на нужные события.
    var outputs = SettingsViewModelOutputs()
    
    init(
        settingsStorage: UserSettingsStorage,
        notificationsService: LocalNotificationsService,
        permissionService: PermissionService
    ) {
        self.settingsStorage = settingsStorage
        self.notificationsService = notificationsService
        self.permissionService = permissionService
    }
    
    /// Первичная загрузка данных.
    func load() async {
        await reloadPermissionsAndRefreshUI()
    }
    
    /// Обработчик переключения любого переключателя (UISwitch) в таблице настроек.
    func didToggleSwitch(for rowID: SettingsRowID, isOn: Bool) async {
        switch rowID {
        case .notifications:
            await handleNotificationsToggle(isOn: isOn)
        case .camera:
            await handleCameraToggle(isOn: isOn)
        case .photos:
            await handlePhotosToggle(isOn: isOn)
        case .tabSwipe:
            handleTabSwipeToggle(isOn: isOn)
        case .theme, .language:
            // Для этих строк используется переход на экран выбора
            break
        }
    }
    
    /// Пользователь тапнул по строке таблицы.
    func didSelectRow(_ rowID: SettingsRowID) {
        switch rowID {
        case .theme:
            outputs.onOpenThemeSelection?()
        case .language:
            outputs.onOpenLanguageSelection?()
        default:
            break
        }
    }
    
    /// Пользователь выбрал конкретную тему в отдельном экране.
    func didSelectTheme(_ theme: AppTheme) {
        settingsStorage.appTheme = theme
        outputs.onThemeChanged?(theme)
        notifyDataChanged()
    }
    
    /// Пользователь выбрал язык приложения.
    func didSelectLanguage(_ language: AppLanguage) {
        // Изменить язык через централизованный менеджер
        LocalizationManager.shared.setLanguage(language)
        
        // Сообщить наружу, что язык изменился
        outputs.onLanguageChanged?(language)
        
        // Обновить данные таблицы
        notifyDataChanged()
    }
    
    /// Обработка тапа по кнопке футера "Открыть настройки" в определённой секции.
    func didTapFooterButton(for sectionID: SettingsSectionID) {
        let kind: PermissionKind
        
        switch sectionID {
        case .notifications:
            // Кнопка в секции уведомлений - переход в настройки уведомлений
            kind = .notifications
            
        case .permissions:
            kind = .camera
            
        case .appearance, .language, .navigation:
            // В этих секциях кнопки "Открыть настройки" нет
            return
        }
        
        outputs.onOpenSystemSettings?(kind)
    }
    
    /// Полная перезагрузка статусов системных разрешений и актуализация хранилища.
    private func reloadPermissionsAndRefreshUI() async {
        // 1. Уведомления: обновить статус из UNUserNotificationCenter через сервис
        await notificationsService.refreshAuthorizationStatus()
        notificationsGranted = (notificationsService.authorizationStatus == .granted)
        
        // Если система разрешает уведомления, а в настройках выключено — включить
        if notificationsGranted && !settingsStorage.notificationsEnabled {
            settingsStorage.notificationsEnabled = true
        }
        
        // 2. Камера и фото: актуализация статусов из PermissionService
        cameraStatus = await permissionService.currentCameraPermissionStatus()
        photoStatus  = await permissionService.currentPhotoLibraryPermissionStatus()
        
        // Камера:
        if cameraStatus == .granted && !settingsStorage.cameraEnabled {
            // Система дала доступ, а флаг в настройках был выключен - включить
            settingsStorage.cameraEnabled = true
        } else if cameraStatus != .granted && settingsStorage.cameraEnabled {
            // Система отобрала доступ, а флаг ещё true - перевести в false
            settingsStorage.cameraEnabled = false
        }
        
        // Фото:
        if photoStatus == .granted && !settingsStorage.photosEnabled {
            settingsStorage.photosEnabled = true
        } else if photoStatus != .granted && settingsStorage.photosEnabled {
            settingsStorage.photosEnabled = false
        }
        
        // 3. Пересобрать секции и уведомить контроллер о новых данных
        notifyDataChanged()
    }
    
    /// Обработка переключения свайпа между вкладками.
    private func handleTabSwipeToggle(isOn: Bool) {
        // Сразу сохранить настройку
        settingsStorage.tabSwipeEnabled = isOn
        
        // Сообщить наверх
        outputs.onTabSwipeChanged?(isOn)
        
        // Обновить данные таблицы
        notifyDataChanged()
    }
    
    /// Обработка переключения разрешения на уведомления.
    private func handleNotificationsToggle(isOn: Bool) async {
        // Текущий статус разрешений на уведомления
        let status = await notificationsService.currentAuthorizationStatus()
        
        switch status {
        case .notDetermined:
            // Первый запрос — показать системный диалог
            let result = await notificationsService.requestAuthorization()
            updateNotificationsAfterRequest(result: result, desiredState: isOn)
            
        case .denied:
            // Доступ запрещён - отправить пользователя в системные настройки
            // Откатываем свитч в выключенное состояние.
            settingsStorage.notificationsEnabled = false
            outputs.onOpenSystemSettings?(.notifications)
            
        case .authorized, .provisional, .ephemeral:
            // Разрешение уже есть - обновить флаг в хранилище
            settingsStorage.notificationsEnabled = isOn
            notifyDataChanged()
            
        @unknown default:
            // На всякий случай
            notificationsGranted = false
            settingsStorage.notificationsEnabled = false
            notifyDataChanged()
        }
    }
    
    /// Обработка переключения разрешения на камеру.
    private func handleCameraToggle(isOn: Bool) async {
        // Обновить локальный флаг в хранилище
        settingsStorage.cameraEnabled = isOn
        
        guard isOn else {
            notifyDataChanged()
            return
        }
        
        // Пользователь включил свитч — запрос системного разрешения
        let result = await permissionService.requestCameraPermission()
        cameraStatus = result
        
        switch result {
        case .granted:
            // Разрешение выдано, оставить флаг включённым
            break
            
        case .denied, .unavailable:
            // Пользователь запретил доступ
            settingsStorage.cameraEnabled = false
            outputs.onPermissionDeniedAlert?(.camera)
        }
        
        notifyDataChanged()
    }
    
    /// Обработка переключения разрешения на доступ к фото.
    private func handlePhotosToggle(isOn: Bool) async {
        // Обновить локальный флаг в хранилище
        settingsStorage.photosEnabled = isOn
        
        guard isOn else {
            notifyDataChanged()
            return
        }
        
        // Пользователь включил свитч — запрос системного разрешения
        let result = await permissionService.requestPhotoLibraryPermission()
        photoStatus = result
        
        switch result {
        case .granted:
            // Разрешение выдано, оставить свитч включённым
            break
            
        case .denied, .unavailable:
            // Доступ запрещён или недоступен
            settingsStorage.photosEnabled = false
            outputs.onPermissionDeniedAlert?(.photos)
        }
        
        notifyDataChanged()
    }
    
    /// Строит массив секций для таблицы настроек.
    private func buildSections() -> [SettingsSectionViewData] {
        var sections: [SettingsSectionViewData] = []
        
        let l10n = LocalizationManager.shared
        
        // Фактическое разрешение на показ уведомлений
        let notificationsOn = settingsStorage.notificationsEnabled && notificationsGranted
        
        let notificationsRow = SettingsRowViewData(
            id: .notifications,
            title: l10n?.localized("settings.notifications.title") ?? "Ежедневные обновления",
            detail: nil,
            isSwitch: true,
            isOn: notificationsOn,
            showsDisclosure: false
        )
        
        let notificationsFooter: SettingsFooterViewData?
        if notificationsFooterNeeded {
            notificationsFooter = SettingsFooterViewData(
                text: l10n?.localized("settings.notifications.footer.text") ?? "",
                showsButton: true,
                buttonTitle: l10n?.localized("settings.openSettings.button") ?? ""
            )
        } else {
            notificationsFooter = nil
        }
        
        sections.append(
            SettingsSectionViewData(
                id: .notifications,
                title: SettingsSectionID.notifications.title, // если это тоже ключ — оставляем, иначе тоже локализуем
                rows: [notificationsRow],
                footer: notificationsFooter
            )
        )
        
        let cameraOn = settingsStorage.cameraEnabled && (cameraStatus == .granted)
        let photoOn  = settingsStorage.photosEnabled && (photoStatus == .granted)
        
        let cameraRow = SettingsRowViewData(
            id: .camera,
            title: l10n?.localized("settings.permissions.camera.title") ??  "Доступ к камере",
            detail: nil,
            isSwitch: true,
            isOn: cameraOn,
            showsDisclosure: false
        )
        
        let photosRow = SettingsRowViewData(
            id: .photos,
            title: l10n?.localized("settings.permissions.photos.title") ?? "Доступ к фото",
            detail: nil,
            isSwitch: true,
            isOn: photoOn,
            showsDisclosure: false
        )
        
        let permissionsFooter: SettingsFooterViewData?
        if permissionsFooterNeeded {
            permissionsFooter = SettingsFooterViewData(
                text: l10n?.localized("settings.permissions.footer.text") ?? "",
                showsButton: true,
                buttonTitle: l10n?.localized("settings.openSettings.button") ?? "",
            )
        } else {
            permissionsFooter = nil
        }
        
        sections.append(
            SettingsSectionViewData(
                id: .permissions,
                title: SettingsSectionID.permissions.title,
                rows: [cameraRow, photosRow],
                footer: permissionsFooter
            )
        )
        
        let themeRow = SettingsRowViewData(
            id: .theme,
            title: l10n?.localized("settings.appearance.theme.title") ?? "Тема",
            detail: currentTheme.title,
            isSwitch: false,
            isOn: false,
            showsDisclosure: true
        )
        
        sections.append(
            SettingsSectionViewData(
                id: .appearance,
                title: SettingsSectionID.appearance.title,
                rows: [themeRow],
                footer: nil
            )
        )
        
        let languageRow = SettingsRowViewData(
            id: .language,
            title: l10n?.localized("settings.language.row.title") ?? "Язык",
            detail: currentLanguage.title,
            isSwitch: false,
            isOn: false,
            showsDisclosure: true
        )
        
        sections.append(
            SettingsSectionViewData(
                id: .language,
                title: SettingsSectionID.language.title,
                rows: [languageRow],
                footer: nil
            )
        )
        
        let tabSwipeRow = SettingsRowViewData(
            id: .tabSwipe,
            title: l10n?.localized("settings.navigation.tabSwipe.title") ?? "Свайп между вкладками",
            detail: nil,
            isSwitch: true,
            isOn: settingsStorage.tabSwipeEnabled,
            showsDisclosure: false
        )
        
        sections.append(
            SettingsSectionViewData(
                id: .navigation,
                title: SettingsSectionID.navigation.title,
                rows: [tabSwipeRow],
                footer: nil
            )
        )
        
        return sections
    }
    
    
    /// Нужно ли показывать футер в секции уведомлений.
    /// Футер появляется, если: уведомления выключены в настройках пользователя или система не дала разрешение на уведомления.
    private var notificationsFooterNeeded: Bool {
        !settingsStorage.notificationsEnabled || !notificationsGranted
    }
    
    /// Нужно ли показывать футер в секции разрешений (камера/фото).
    /// Футер появляется, если хотя бы один из доступов  выключен.
    private var permissionsFooterNeeded: Bool {
        let cameraOn = settingsStorage.cameraEnabled && (cameraStatus == .granted)
        let photoOn  = settingsStorage.photosEnabled && (photoStatus == .granted)
        return !(cameraOn && photoOn)
    }
    
    /// Пересобирает секции и вызывает `onDataChanged` с новыми данными.
    private func notifyDataChanged() {
        let sections = buildSections()
        outputs.onDataChanged?(sections)
    }
    
    /// Обновляет внутреннее состояние после запроса разрешения на уведомления.
    private func updateNotificationsAfterRequest(
        result: UNAuthorizationStatus,
        desiredState: Bool
    ) {
        switch result {
        case .authorized, .provisional, .ephemeral:
            // Система разрешила уведомления
            notificationsGranted = true
            settingsStorage.notificationsEnabled = desiredState
            
        case .denied:
            // Пользователь явно отказался
            notificationsGranted = false
            settingsStorage.notificationsEnabled = false
            outputs.onPermissionDeniedAlert?(.notifications)
            
        case .notDetermined:
            notificationsGranted = false
            settingsStorage.notificationsEnabled = false
            
        @unknown default:
            notificationsGranted = false
            settingsStorage.notificationsEnabled = false
        }
        
        notifyDataChanged()
    }
}
