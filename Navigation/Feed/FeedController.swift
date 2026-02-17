import UIKit

final class FeedViewController: UIViewController {
    
    private let feedModel = FeedModel()
    
    private lazy var feedView: FeedView = {
        let view = FeedView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tappedOnButton = { [weak self] text in
            self?.checkGuess(text: text)
        }
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFeedView()
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
    
    private func checkGuess(text: String) {
        guard !text.isEmpty else {
            feedView.showEmptyTextField()
            return
        }
        let isCorrect = feedModel.check(word: text)
        feedView.showResult(isCorrect: isCorrect)
    }
}
