import Foundation

struct FeedPost {
    public let author: String
    public let title: String
    public let image: String = "Image.png"
    public let description: String
    public var likes: Int
    public var views: Int
}

protocol FeedViewModelInput {
    func viewDidLoad()
    func viewWillAppear()
    func viewWillDisappear()
}

protocol FeedViewModelOutput: AnyObject {
    var postsUpdated: (() -> Void)? { get set }
    var numberOfPosts: Int { get }
    var postInsertedAtTop: ((Int) -> Void)? { get set }
    var onError: ((NavigationError) -> Void)? { get set }
    func post(at index: Int) -> FeedPost
}

final class FeedViewModel: FeedViewModelInput, FeedViewModelOutput {
    
    var postsUpdated: (() -> Void)?
    var postInsertedAtTop: ((Int) -> Void)?
    var numberOfPosts: Int { posts.count }
    var onError: ((NavigationError) -> Void)?
    
    private var posts: [FeedPost] = []
    private var updateTimer: Timer?
    private let storage: PostStorageProtocol
    
    var randomBool: () -> Bool = { Bool.random() }
    
    init(storage: PostStorageProtocol = PostStorage()) {
        self.storage = storage
    }
    
    func post(at index: Int) -> FeedPost {
        posts[index]
    }
    
    func viewDidLoad() {
        loadFeed()
    }
    
    func viewWillAppear() {
        startAutoUpdateTimer()
    }
    
    func viewWillDisappear() {
        stopAutoUpdateTimer()
    }
    
    private func startAutoUpdateTimer() {
        stopAutoUpdateTimer()
        
        updateTimer = Timer.scheduledTimer(
            timeInterval: 15.0,
            target: self,
            selector: #selector(didUpdateTimer),
            userInfo: nil,
            repeats: true
        )
        
        if let timer = updateTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopAutoUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    @objc func didUpdateTimer() {
        loadMorePosts()
    }
    
    private func loadMorePosts() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let success = self.randomBool()
            if success {
                guard let newPost = self.storage.makeRandomPost() else {
                    DispatchQueue.main.async {
                        self.onError?(.feedUpdateFailed)
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.posts.insert(newPost, at: 0)
                    self.postInsertedAtTop?(0)
                }
            } else {
                DispatchQueue.main.async {
                    self.onError?(.feedUpdateFailed)
                }
            }
        }
    }
    
    private func fetchPosts(completion: @escaping (Result<[FeedPost], NavigationError>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let storedPosts = self.storage.posts
            if storedPosts.isEmpty {
                DispatchQueue.main.async {
                    completion(.failure(.feedLoadingFailed))
                }
            } else {
                let posts = Array(storedPosts.reversed())
                DispatchQueue.main.async {
                    completion(.success(posts))
                }
            }
        }
    }
    
    private func loadFeed() {
        fetchPosts { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let newPosts):
                self.posts = newPosts
                self.postsUpdated?()
            case .failure(let error):
                self.onError?(error)
            }
        }
    }
}

