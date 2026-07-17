import Foundation

struct AppInfoViewData {
    let appName: String
    let version: String
    let author: String
    let goal: String?
    let technologies: String?
    let year: String?
}

final class AppInfoViewModel {

    let data: AppInfoViewData

    init(config: AppInfoConfig = AppInfoStatic.infoData) {
        self.data = AppInfoViewData(
            appName: config.appName,
            version: config.version,
            author: config.author,
            goal: config.goal,
            technologies: config.technologies,
            year: config.year
        )
    }
}
