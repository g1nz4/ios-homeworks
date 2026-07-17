import UIKit

protocol StoryViewerFactory {
    @MainActor
    func makeViewerForProfile(user: User) -> UIViewController

    @MainActor
    func makeViewerForFeed(story: FeedStory) async -> UIViewController?
}

final class DefaultStoryViewerFactory: StoryViewerFactory {
   
    private let coreDataStorage: CDStoryStorageProtocol
    private let localStorage: LocalStoryServiceProtocol

    init(
        coreDataStorage: CDStoryStorageProtocol,
        localStorage: LocalStoryServiceProtocol
    ) {
        self.coreDataStorage = coreDataStorage
        self.localStorage = localStorage
    }

    // Профиль: CoreData
    @MainActor
    func makeViewerForProfile(user: User) -> UIViewController {
        let timer = StoryTimer()
        let vm = StoryPlayerViewModel(
            itemDuration: 5.0,
            timer: timer,
            storage: coreDataStorage,
            userId: user.id
        )

        let vc = StoryViewController(
            playerViewModel: vm,
            mode: .viewOnly,
            userName: user.name.displayName,
            avatarURLString: user.avatarURL?.absoluteString
        )
        return vc
    }

    // Лента: картинки из сети [Data]
    @MainActor
    func makeViewerForFeed(story: FeedStory) async -> UIViewController? {
        let datas = await ImageLoader.shared.loadImages(for: story)
        guard !datas.isEmpty else { return nil }

        let vm = StoryPlayerViewModel(
            items: datas,
            createdAt: story.createdAt,
            timer: StoryTimer()
        )

        let vc = StoryViewController(
            playerViewModel: vm,
            mode: .viewOnly,
            userName: story.authorName,
            avatarURLString: story.avatarURL
        )
        return vc
    }
}
