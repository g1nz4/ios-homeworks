import Foundation
import StorageService

protocol ProfileViewModelInput {
    func viewDidLoad()
    func didSelectRow(section: Int, row: Int)
}

protocol ProfileViewModelOutput {
    var updateHeader: ((User) -> Void)? { get set }
    var updatePosts: (() -> Void)? { get set }
    var showPhotos: (() -> Void)? { get set }
    
    func numberOfSections() -> Int
    func numberOfRows(in section: Int) -> Int
    func cellType(for section: Int) -> ProfileCellType
    func post(section: Int, row: Int) -> MyPost?
}

enum ProfileCellType {
    case photos
    case posts
    case none
}

final class ProfileViewModel: ProfileViewModelInput, ProfileViewModelOutput {
    
    private let user: User
    private let postsLoader: () -> [MyPost]
    private var posts: [MyPost] = []
    
    var updateHeader: ((User) -> Void)?
    var updatePosts: (() -> Void)?
    var showPhotos: (() -> Void)?
    
    init(
        user: User,
        postsLoader: @escaping () -> [MyPost] = { MyPost.make() }
    ){
        self.user = user
        self.postsLoader = postsLoader
    }
    
    func viewDidLoad() {
        updateHeader?(user)
        posts = postsLoader()
        updatePosts?()
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
}
