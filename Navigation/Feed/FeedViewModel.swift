import Foundation

protocol FeedViewModelInput {
    func checkGuess(word: String)
}

protocol FeedViewModelOutput {
    var emptyTextField: (() -> Void)? { get set }
    var result: ((Bool) -> Void)? { get set }
}

final class FeedViewModel: FeedViewModelInput, FeedViewModelOutput {
    private let model: FeedModel
    
    var emptyTextField: (() -> Void)?
    var result: ((Bool) -> Void)?
    
    init(model: FeedModel = FeedModel()) {
        self.model = model
    }
    
    func checkGuess(word: String) {
        guard !word.isEmpty else {
            emptyTextField?()
            return
        }
        let isCorrect = model.check(word: word)
        result?(isCorrect)
    }
}
