import Foundation

extension Notification.Name {
    static let savedPhotosDidChange = Notification.Name("savedPhotosDidChange")
    static let currentUserDidUpdate = Notification.Name("currentUserDidUpdate")
    static let currentUserDidChange = Notification.Name("currentUserDidChange")
    static let appLanguageDidChange = Notification.Name("appLanguageDidChange")
}

struct CurrentUserUpdateKey {
    static let user = "user"
}
