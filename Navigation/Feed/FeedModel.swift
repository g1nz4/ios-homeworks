import UIKit

final class FeedModel {
    
    private let secretWord: String
    
    init(secretWord: String = "Cat") {
        self.secretWord = secretWord
    }
    
    func check(word: String) -> Bool {
        word == secretWord
    }
}
