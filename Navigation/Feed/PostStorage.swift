import Foundation

protocol PostStorageProtocol {
    var posts: [FeedPost] { get }
    func makeRandomPost() -> FeedPost?
}

final class PostStorage: PostStorageProtocol {
    
    private(set) var posts: [FeedPost] = [
        FeedPost(
            author: "Иван Иванов",
            title: "Первый пост",
            description: "Это описание первого поста в нашей ленте",
            likes: 12,
            views: 120
        ),
        FeedPost(
            author: "Михаил Крот",
            title: "Фото с путешествия",
            description: "Красивый вид на море и горы",
            likes: 34,
            views: 250
        ),
        FeedPost(
            author: "Navigation App",
            title: "Обновление приложения",
            description: "Мы добавили автообновление ленты каждые 15 секунд",
            likes: 20,
            views: 180
        )
    ]
    
    private let postsForExperiment: [FeedPost] = [
        FeedPost(
            author: "User1",
            title: "Новый день",
            description: "Утренний кофе и планы на день",
            likes: 0,
            views: 0
        ),
        FeedPost(
            author: "User2",
            title: "Спорт",
            description: "Пробежка в парке",
            likes: 0,
            views: 0
        ),
        FeedPost(
            author: "User3",
            title: "Собака",
            description: "Лучший друг человека",
            likes: 0,
            views: 0
        ),
        FeedPost(
            author: "User4",
            title: "Навигация",
            description: "Тестируем новое приложение",
            likes: 0,
            views: 0),
        FeedPost(
            author: "User5",
            title: "Завтрак",
            description: "Которого нет в меню",
            likes: 0,
            views: 0),
        FeedPost(
            author: "User6",
            title: "Учёба",
            description: "Делаю домашку по iOS.",
            likes: 0,
            views: 0
        ),
        FeedPost(
            author: "User7",
            title: "Книга",
            description: "Которую недавно прочитал",
            likes: 0,
            views: 0
        ),
        FeedPost(
            author: "User8",
            title: "Город",
            description: "Без проишествий и шума",
            likes: 0,
            views: 0
        ),
        FeedPost(
            author: "User9",
            title: "Сериал",
            description: "Игра в кальмара",
            likes: 0,
            views: 0
        ),
        FeedPost(
            author: "User10",
            title: "Музыка",
            description: "Для релаксации",
            likes: 0,
            views: 0
        )
    ]
    
    func makeRandomPost() -> FeedPost? {
        guard let newPost = postsForExperiment.randomElement() else {
            return nil
        }
        var post = newPost
        post.likes = Int.random(in: 0...50)
        post.views = Int.random(in: 10...200)
        return post
    }
}
