import Foundation

final class PasswordBruteForcer {
    
    private let allowedCharacters: [String] = {
        let digits = "0123456789"
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        
        return (digits + lowercase + uppercase).map { String($0) }
    }()
    
    private func indexOf(
        character: Character,
        _ array: [String]
    ) -> Int {
        return array.firstIndex(of: String(character))!
    }
    
    private func characterAt(
        index: Int,
        _ array: [String]
    ) -> Character {
        return index < array.count ? Character(array[index]) : Character("")
    }
    
    private func generateBruteForce(_ string: String) -> String {
        var str: String = string

        if str.count <= 0 {
            str.append(characterAt(index: 0, allowedCharacters))
        } else {
            str.replace(at: str.count - 1,
                        with: characterAt(
                            index: (indexOf(character: str.last!, allowedCharacters) + 1) % allowedCharacters.count,
                            allowedCharacters)
            )

            if indexOf(character: str.last!, allowedCharacters) == 0 {
                str = String(generateBruteForce(String(str.dropLast()))) + String(str.last!)
            }
        }

        return str
    }
    
    func bruteForce(
        target: String,
        progress: @escaping (String) -> Void,
        completion: @escaping (String) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var password = ""
            var lastUpdate = Date()

            while password != target {
                password = self.generateBruteForce(password)

                let now = Date()
                if now.timeIntervalSince(lastUpdate) > 0.05 {
                    lastUpdate = now
                    let current = password
                    DispatchQueue.main.async {
                        progress(current)
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(password)
            }
        }
    }
}

extension String {
  
    mutating func replace(
    at index: Int,
    with character: Character
   ) {
       var stringArray = Array(self)
       stringArray[index] = character
       self = String(stringArray)
   }
}
