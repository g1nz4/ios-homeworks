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
    func post(at index: Int) -> FeedPost
}

final class FeedViewModel: FeedViewModelInput, FeedViewModelOutput {
    
    var postsUpdated: (() -> Void)?
    var postInsertedAtTop: ((Int) -> Void)?
    var numberOfPosts: Int { posts.count }
    
    private var posts: [FeedPost] = []
    private var updateTimer: Timer?
    private let storage = PostStorage()
    
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
    
    @objc private func didUpdateTimer() {
        loadMorePosts()
    }
    
    private func loadMorePosts() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let newPost = self.storage.makeRandomPost()
    
            DispatchQueue.main.async {
                self.posts.insert(newPost, at: 0)
                self.postInsertedAtTop?(0)
            }
        }
    }
    
    private func fetchPosts(completion: @escaping ([FeedPost]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let storedPosts = self.storage.posts.reversed()
           
            DispatchQueue.main.async {
                completion(Array(storedPosts))
            }
        }
    }
    
    private func loadFeed() {
        fetchPosts { [weak self] newPosts in
            guard let self = self else { return }
            self.posts = newPosts
            self.postsUpdated?()
        }
    }
}
