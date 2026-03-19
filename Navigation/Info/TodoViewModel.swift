import Foundation

protocol TodoViewModelProtocol {
    var title: Observable<String> { get }
    var isLoading: Observable<Bool> { get }
    
    func viewDidLoad()
    func update()
}

final class TodoViewModel: TodoViewModelProtocol {
    
    let title: Observable<String> = Observable("Загрузка данных...")
    let isLoading: Observable<Bool> = Observable(false)
    
    private let baseURL: String = "https://jsonplaceholder.typicode.com/todos/"
    private let IdRange = 1...200
    
    func viewDidLoad() {
        loadTodo()
    }
    
    func update() {
        loadTodo()
    }
    
    private func loadTodo() {
        Task { [weak self] in
            await self?.requestTodo()
        }
    }
    
    private func requestTodo() async {
        let randomId = Int.random(in: IdRange)
        let todoURL = baseURL + "\(randomId)"
        
        guard let url = URL(string: todoURL) else {
            title.value = NetworkError.invalidURL.rawValue
            return
        }
        
        isLoading.value = true

        defer {
            isLoading.value = false
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                title.value = NetworkError.errorReceivingData.rawValue
            }
            
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
           
            guard let dictionary = jsonObject as? [String: Any] else {
                title.value = NetworkError.decodingFailed.rawValue
                return
            }
            
            let userId = dictionary["userId"] as? Int ?? 0
            let id = dictionary["id"] as? Int ?? 0
            let titleText = dictionary["title"] as? String ?? "Title не найден"
            let completed = dictionary["completed"] as? Bool ?? false
            
            let todo = Todo(userId: userId, id: id, title: titleText, completed: completed)
            title.value = todo.title
        } catch {
            title.value = "\(error.localizedDescription)"
        }
    }
}
