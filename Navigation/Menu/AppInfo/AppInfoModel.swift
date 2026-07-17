import Foundation

struct AppInfoConfig {
    let appName: String
    let version: String
    let author: String
    let goal: String?
    let technologies: String?
    let year: String?
}

enum AppInfoStatic {
    static let infoData = AppInfoConfig(
        appName: "VK Client (учебный проект)",
        version: "1.0.0",
        author: "Мишенина Евгения",
        goal: "Разработка клиентского приложения соцсети.",
        technologies:
            """
            - Swift, 
            - MVVM,
            - Coordinator,
            - Swift Concurrency, 
            - UIKit, 
            - Autolayout, 
            - URLSession, 
            - Codable, 
            - Keychain, 
            - CoreData, 
            - Custom Tab Bar, 
            - Localaizable, 
            - AVAudioPlayer,
            - UserDefaults,
            - UICollectionViewCompositionalLayout
            """,
        year: "2026"
    )
}
