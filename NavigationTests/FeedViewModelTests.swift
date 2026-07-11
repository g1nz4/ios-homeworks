//import XCTest
//@testable import Navigation
//
//final class PostStorageMock: PostStorageProtocol {
//    var posts: [FeedPost] = []
//    var randomPostToReturn: FeedPost?
//
//    func makeRandomPost() -> FeedPost? {
//        return randomPostToReturn
//    }
//}
//
//final class FeedViewModelTests: XCTestCase {
//
//    var storageMock: PostStorageMock!
//    var viewModel: FeedViewModel!
//    
//    override func setUpWithError() throws {
//        try super.setUpWithError()
//        storageMock = PostStorageMock()
//        viewModel = FeedViewModel(storage: storageMock)
//    }
//    
//    override func tearDownWithError() throws {
//        storageMock = nil
//        viewModel = nil
//        try super.tearDownWithError()
//    }
//    
//    func test_viewDidLoad_loadsPostsSuccessfully() {
//        // given
//        let post1 = FeedPost(
//            author: "author1",
//            title: "title1",
//            description: "description1",
//            likes: 1,
//            views: 1
//        )
//        let post2 = FeedPost(
//            author: "author2",
//            title: "title2",
//            description: "description2",
//            likes: 2,
//            views: 2
//        )
//        storageMock.posts = [post1, post2]
//        
//        let expectation = expectation(description: "postsUpdated called")
//        viewModel.postsUpdated = {
//            expectation.fulfill()
//        }
//        
//        // when
//        viewModel.viewDidLoad()
//        
//        // then
//        waitForExpectations(timeout: 1.0)
//        XCTAssertEqual(viewModel.numberOfPosts, 2)
//        XCTAssertEqual(viewModel.post(at: 0).author, "author2")
//        XCTAssertEqual(viewModel.post(at: 1).author, "author1")
//    }
//    
//    func test_viewDidLoad_whenStoragePostsEmpty_callsOnErrorWithFeedLoadingFailed() {
//        // given
//        storageMock.posts = []
//        
//        let expectation = expectation(description: "onError called")
//        var receivedError: NavigationError?
//        
//        viewModel.onError = { error in
//            receivedError = error
//            expectation.fulfill()
//        }
//        
//        // when
//        viewModel.viewDidLoad()
//        
//        // then
//        waitForExpectations(timeout: 1.0)
//        XCTAssertEqual(receivedError, .feedLoadingFailed)
//        XCTAssertEqual(viewModel.numberOfPosts, 0)
//    }
//
//    func test_didUpdateTimer_onSuccess_insertsPostAtTop() {
//        // given
//        let newPost = FeedPost(
//            author: "NewAuthor",
//            title: "NewTitle",
//            description: "NewDescription",
//            likes: 0,
//            views: 0
//        )
//        storageMock.randomPostToReturn = newPost
//        
//        viewModel.randomBool = { true }
//        
//        let expectation = expectation(description: "postInsertedAtTop called")
//        viewModel.postInsertedAtTop = { index in
//            XCTAssertEqual(index, 0)
//            expectation.fulfill()
//        }
//        
//        // when
//        viewModel.didUpdateTimer()
//        
//        // then
//        waitForExpectations(timeout: 1.0)
//        XCTAssertEqual(viewModel.numberOfPosts, 1)
//        XCTAssertEqual(viewModel.post(at: 0).title, "NewTitle")
//        XCTAssertEqual(viewModel.post(at: 0).author, "NewAuthor")
//        XCTAssertEqual(viewModel.post(at: 0).description, "NewDescription")
//    }
//}
