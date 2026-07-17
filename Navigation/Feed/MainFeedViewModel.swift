import Foundation

/// Главный VM для экрана ленты.
/// Разделён на две внутренние части:
/// 1.  storiesViewModel  — управляет сторисами
/// 2.  postsViewModel    — управляет постами

@MainActor
final class MainFeedViewModel {

    enum Section: Int, CaseIterable {
        case stories = 0
        case posts   = 1
    }

    let storiesViewModel: FeedStoriesViewModel
    let postsViewModel:  FeedPostsViewModel
    
    var currentUser: User { postsViewModel.currentUser }

    /// Точечные обновления: какая секция и какие item‑индексы изменились.
    var onItemsUpdated: ((Section, [Int]) -> Void)?

    /// Полный reload (первичная загрузка, pull‑to‑refresh).
    var onReloadAll: (() -> Void)?

    init(
        currentUserId: String,
        storyService: LocalStoryServiceProtocol,
        feedService: LocalFeedServiceProtocol,
        postService: PostServiceProtocol,
        photosRepository: PhotosRepositoryProtocol,
        currentUser: User
    ) {
        self.storiesViewModel = FeedStoriesViewModel(
            currentUserId: currentUserId,
            storyService: storyService
        )

        self.postsViewModel = FeedPostsViewModel(
            feedService: feedService,
            postService: postService,
            photosRepository: photosRepository,
            currentUser: currentUser
        )

        bindStories()
        bindPosts()
    }

    /// Пробрасывает обновления сторис в общий onItemsUpdated.
    private func bindStories() {
        storiesViewModel.onStoriesUpdated = { [weak self] indices in
            self?.onItemsUpdated?(.stories, indices)
        }
    }

    /// Пробрасывает обновления постов в общий onItemsUpdated.
    private func bindPosts() {
        postsViewModel.onPostsUpdated = { [weak self] indices in
            self?.onItemsUpdated?(.posts, indices)
        }
    }
    
    /// Параллельная загрузка сторис и постов.
    func load() async {
        async let storiesTask: Void = storiesViewModel.load()
        async let postsTask:   Void = postsViewModel.load()

        _ = await (storiesTask, postsTask)
        onReloadAll?()
    }

    /// Количество VM‑секций (stories + posts).
    func numberOfSections() -> Int {
        Section.allCases.count
    }

    /// Количество элементов в заданной секции по индексу (0: stories, 1: posts).
    func numberOfItems(in sectionIndex: Int) -> Int {
        guard let section = Section(rawValue: sectionIndex) else { return 0 }

        switch section {
        case .stories: return storiesViewModel.numberOfItems()
        case .posts:   return postsViewModel.numberOfItems()
        }
    }

    /// Модель сторис для конкретного индекса.
    func story(at index: Int) -> FeedStory {
        storiesViewModel.story(at: index)
    }

    /// Модель поста для конкретного индекса.
    func post(at index: Int) -> MyPost {
        postsViewModel.post(at: index)
    }

    /// Пометить сторис как просмотренную (используется при возврате с viewer).
    func markStoryViewed(in sectionIndex: Int, itemIndex: Int) {
        guard let section = Section(rawValue: sectionIndex),
              section == .stories
        else { return }

        storiesViewModel.markViewed(at: itemIndex)
    }

    func toggleExpanded(at index: Int) {
        postsViewModel.toggleExpanded(at: index)
    }

    func toggleLike(at index: Int) async {
        await postsViewModel.toggleLike(at: index)
    }

    func toggleFavorite(at index: Int) async {
        await postsViewModel.toggleFavorite(at: index)
    }

    func addPostToWall(at index: Int) async {
        await postsViewModel.addPostToWall(at: index)
    }

    func incrementViews(at index: Int) async {
        await postsViewModel.incrementViews(at: index)
    }

    func addToSaved(photo: Photo) async {
        await postsViewModel.addToSaved(photo: photo)
    }
}
