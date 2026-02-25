import UIKit

final class FeedViewController: UIViewController {
    
    private var feedViewModel: (FeedViewModelInput & FeedViewModelOutput)
   
    var showPost: (() -> Void)?
    
    private lazy var feedView: FeedView = {
        let view = FeedView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tappedOnButton = { [weak self] text in
            self?.feedViewModel.checkGuess(word: text)
        }
        view.tappedOnShowPost = { [weak self] in
            self?.showPost?()
        }
        
        return view
    }()
    
    init(feedViewModel: FeedViewModelInput & FeedViewModelOutput = FeedViewModel()){
        self.feedViewModel = feedViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindingViewModel()
        setupFeedView()
    }
    
    private func bindingViewModel() {
        feedViewModel.emptyTextField = { [weak self] in
            self?.feedView.showEmptyTextField()
        }
        feedViewModel.result = { [weak self] isCorrect in
            self?.feedView.showResult(isCorrect: isCorrect)
        }
    }
    
    private func setupFeedView() {
        view.addSubview(feedView)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            feedView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            feedView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            feedView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            feedView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16)
        ])
    }
}
