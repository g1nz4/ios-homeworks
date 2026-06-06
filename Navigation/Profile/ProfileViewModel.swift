import Foundation
import StorageService

protocol ProfileViewModelInput {
    func viewDidLoad()
    func didSelectRow(section: Int, row: Int)
    func updateStatus(_ text: String)
    func didDoubleTap(post: MyPost)
    func insert(post: MyPost, at row: Int)
}

protocol ProfileViewModelOutput {
    var updateHeader: ((User) -> Void)? { get set }
    var updatePosts: (() -> Void)? { get set }
    var showPhotos: (() -> Void)? { get set }
    var onError: ((NavigationError) -> Void)? { get set }
    var onStatusChanged: ((String) -> Void)? { get set }
    
    func numberOfSections() -> Int
    func numberOfRows(in section: Int) -> Int
    func cellType(for section: Int) -> ProfileCellType
    func post(section: Int, row: Int) -> MyPost?
    func isFavorite(postID: String) -> Bool
}

enum ProfileCellType {
    case photos
    case posts
    case none
}

final class ProfileViewModel: ProfileViewModelInput, ProfileViewModelOutput {
    
    private var user: User
    private var posts: [MyPost] = []
    private var favoriteIDs: Set<String> = []
    private let postsLoader: () -> [MyPost]
    private let favoritesStorage: CoreDataFavoritesPostProtocol
    
    var updateHeader: ((User) -> Void)?
    var updatePosts: (() -> Void)?
    var showPhotos: (() -> Void)?
    var onError: ((NavigationError) -> Void)?
    var onStatusChanged: ((String) -> Void)?
    
    init(
        user: User,
        postsLoader: @escaping () -> [MyPost] = { MyPost.make() },
        favoritesStorage: CoreDataFavoritesPostProtocol = CoreDataManager()
    ){
        self.user = user
        self.postsLoader = postsLoader
        self.favoritesStorage = favoritesStorage
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(favoritesDidChange),
            name: .favoritesDidChange,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func viewDidLoad() {
        fetchProfile { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let user):
                self.updateHeader?(user)
            case .failure(let error):
                self.onError?(error)
            }
        }
        posts = postsLoader()
        updatePosts?()
        reloadFavorites()
    }
    
    private func reloadFavorites() {
        Task { [weak self] in
            guard let self else { return }
            
            do {
                let favorites = try await favoritesStorage.fetchAll()
                let ids = Set(favorites.map { $0.id })
                
                await MainActor.run {
                    self.favoriteIDs = ids
                    self.updatePosts?()
                }
            } catch {
                await MainActor.run {
                    self.onError?(.favoritesLoadingFailed)
                }
            }
        }
    }
    
    @objc private func favoritesDidChange() {
        reloadFavorites()
    }
    
    private func fetchProfile(completion: @escaping (Result<User, NavigationError>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let profileUser = self.user
            
            let success = true
            DispatchQueue.main.async {
                if success {
                    completion(.success(profileUser))
                } else {
                    completion(.failure(.profileLoadingFailed))
                }
            }
        }
    }
    
    func updateStatus(_ text: String) {
        let statusText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !statusText.isEmpty else {
            onError?(.statusUpdateFailed)
            return
        }
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            self.user.status = statusText
            DispatchQueue.main.async {
                self.onStatusChanged?(statusText)
                self.updateHeader?(self.user)
            }
        }
    }
    
    func didSelectRow(section: Int, row: Int) {
        if section == 1 && row == 0 {
            showPhotos?()
        }
    }
    
    func numberOfSections() -> Int {
        3
    }
    
    func numberOfRows(in section: Int) -> Int {
        switch section {
        case 0: return 0
        case 1: return 1
        case 2: return posts.count
        default: return 0
        }
    }
    
    func cellType(for section: Int) -> ProfileCellType {
        switch section {
        case 1: return .photos
        case 2: return .posts
        default: return .none
        }
    }
    
    func post(section: Int, row: Int) -> MyPost? {
        guard section == 2, posts.indices.contains(row) else {
            return nil
        }
        return posts[row]
    }
    
    func isFavorite(postID: String) -> Bool {
        favoriteIDs.contains(postID)
    }
    
    func didDoubleTap(post: MyPost) {
        Task { [weak self] in
            guard let self else { return }
           
            do {
                try await favoritesStorage.save(post: post)
                
                await MainActor.run {
                    self.favoriteIDs.insert(post.id)
                    self.updatePosts?()
                }
            } catch {
                await MainActor.run {
                    self.onError?(.favoritesSavingFailed)
                }
            }
        }
    }
    
    func insert(post: MyPost, at row: Int) {
        let index = min(max(row, 0), posts.count)
        posts.insert(post, at: index)
        updatePosts?()
    }
}
