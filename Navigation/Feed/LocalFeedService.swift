import UIKit

/// Протокол сервиса ленты. (Протокол, чтобы можно было подменять реализацию в тестах)
protocol LocalFeedServiceProtocol: AnyObject {
    /// Получить ленту постов для пользователя
    func fetchFeed(for userId: String) async throws -> [MyPost]
    /// Поставить или снять лайк у поста
    func setLike(_ isLiked: Bool, for postId: String) async throws
    /// Обновить количество просмотров поста
    func updateViews(id: String, views: Int) async throws
}

/// Локальная реализация сервиса ленты.
/// Хранит посты в памяти и имитирует сетевые задержки.
final class LocalFeedService: LocalFeedServiceProtocol {

    /// Массив постов, живёт только в памяти
    private var posts: [MyPost] = []

    init() {
        seedPosts()
    }

    /// Заполнение массива постов тестовыми данными
    private func seedPosts() {
        posts = [
            MyPost(
                id: "001",
                authorId: "001",
                author: "Swift | SwiftUI | iOS Сообщество разработчиков",
             
                description: "Подготовили для вас шпаргалку по Safe Area",
                likes: 12,
                views: 120,
                isExpanded: false,
                isLiked: false,
                isFavorite: false,
                createdAt: makeDate(year: 2026, month: 07, day: 3, hour: 10, minute: 0),
                authorAvatarPath: "https://sun9-42.userapi.com/s/v1/ig2/le0Rkuizz88qInuhH-jLZ7D7txeEbc1s-pRA06qZPnX7UjXFZBVmpAIDXJYPRTgVmMr5JToqic80vZasH3SSbDRA.jpg?quality=95&as=32x35,48x52,72x78,108x117,160x174,240x261,360x391,480x521,540x586,640x695,720x782,1024x1112&from=bu&u=c8MY7mKehpgMln3hsfK1CmZQ2eyrV1sWzgAJT9AkuOs&cs=1024x0",
                imagePath: "https://sun9-42.userapi.com/s/v1/ig2/eKU1gtIsxnqsNMkOMN5ME4bJz10gNiLO7vmRkPavRVBNmTa7sBz7H3_gTgd8uKhT0dTyi25-rr9i5izbudgzMcVw.jpg?quality=95&crop=0,0,1024,1536&as=32x48,48x72,72x108,108x162,160x240,240x360,360x540,480x720,540x810,640x960,720x1080,1024x1536&from=bu&u=bE7DwtfGvLA7qsqWZSB081DmOH49-r-_-P41aqGmupY&cs=640x0"
            ),
            MyPost(
                id: "002",
                authorId: "001",
                author: "Swift | SwiftUI | iOS Сообщество разработчиков",
               
                description: """
                    MCP — это Model Context Protocol, открытый стандарт, который позволяет ИИ подключаться к внешним программам, данным и инструментам. Его часто сравнивают с USB-C для нейросетей: один общий способ подключения вместо отдельной интеграции для каждого сервиса.

                    Например, через MCP Claude может:

                    - читать выбранный макет из Figma;
                    - работать с файлами проекта;
                    - обращаться к базе данных;
                    - получать задачи из Jira;
                    - запускать команды и внутренние инструменты компании.

                    Как это устроено

                    Есть две основные части:

                    MCP-клиент — программа, в которой работает ИИ. Например, Claude Code или IDE.

                    MCP-сервер — небольшой посредник, который предоставляет ИИ конкретные возможности: инструменты, данные и готовые команды.

                    MCP появился 25 ноября 2024 года. В этот день компания Anthropic представила и открыла исходный код Model Context Protocol как стандарт для подключения ИИ к внешним данным и инструментам.
                    """,
                likes: 30,
                views: 240,
                isExpanded: false,
                isLiked: false,
                isFavorite: false,
                createdAt: makeDate(year: 2026, month: 07, day: 1, hour: 14, minute: 34),
                authorAvatarPath: "https://sun9-42.userapi.com/s/v1/ig2/le0Rkuizz88qInuhH-jLZ7D7txeEbc1s-pRA06qZPnX7UjXFZBVmpAIDXJYPRTgVmMr5JToqic80vZasH3SSbDRA.jpg?quality=95&as=32x35,48x52,72x78,108x117,160x174,240x261,360x391,480x521,540x586,640x695,720x782,1024x1112&from=bu&u=c8MY7mKehpgMln3hsfK1CmZQ2eyrV1sWzgAJT9AkuOs&cs=1024x0",
                imagePath: "https://sun9-70.userapi.com/s/v1/ig2/g4na3AhL9cHTbczEMvXSbpXKOldQAoN-Xi1e96Hih8AX-OpUTyoPood4x1xM77QhMU1wAEZMkGAFqCOZg-LEo_7r.jpg?quality=95&crop=0,0,1402,1122&as=32x26,48x38,72x58,108x86,160x128,240x192,360x288,480x384,540x432,640x512,720x576,1080x864,1280x1024,1402x1122&from=bu&u=x5uU8opmdOI3w2JtRyjoKVuSID7LGxEjvfzUpF4fPI4&cs=640x0"
            ),
            MyPost(
                id: "003",
                authorId: "001",
                author: "Swift | SwiftUI | iOS Сообщество разработчиков",
               
                description: """
                    ☝🏻Что такое bash и zsh

                    Bash и zsh — это командные оболочки: программы, которые принимают команды в Терминале и запускают их.

                    bash — сокращение от Bourne Again Shell. Это очень распространённая оболочка в Linux. Также долгое время Bash был оболочкой по умолчанию в macOS.

                    zsh — сокращение от Z Shell.
                    Это более современная оболочка с дополнительными удобствами:

                    - улучшенное автодополнение;
                    - более удобная работа с историей команд;
                    - исправление некоторых опечаток;
                    - поддержка тем и плагинов;
                    - удобная настройка приглашения командной строки.

                    Начиная с macOS Catalina, zsh является оболочкой по умолчанию в macOS.
                    """,
                likes: 56,
                views: 320,
                isExpanded: false,
                isLiked: false,
                isFavorite: false,
                createdAt: makeDate(year: 2026, month: 07, day: 13, hour: 10, minute: 9),
                authorAvatarPath: "https://sun9-42.userapi.com/s/v1/ig2/le0Rkuizz88qInuhH-jLZ7D7txeEbc1s-pRA06qZPnX7UjXFZBVmpAIDXJYPRTgVmMr5JToqic80vZasH3SSbDRA.jpg?quality=95&as=32x35,48x52,72x78,108x117,160x174,240x261,360x391,480x521,540x586,640x695,720x782,1024x1112&from=bu&u=c8MY7mKehpgMln3hsfK1CmZQ2eyrV1sWzgAJT9AkuOs&cs=1024x0",
                imagePath: "https://sun9-52.userapi.com/s/v1/ig2/ZgdajTtUEMFzYcoVJ1WwfI8rtgrL15pSJvqocWyk8fsfAuWJ_78rtG-qM_GdIHMFlCy1QM9B4z8BGfQaIJXu-q3s.jpg?quality=95&crop=0,0,2560,1706&as=32x21,48x32,72x48,108x72,160x107,240x160,360x240,480x320,540x360,640x426,720x480,1080x720,1280x853,1440x960,2560x1706&from=bu&u=PPu0BYMXH795QhV2wcVGlwvkDRKZbejzuBtKrVZvQJo&cs=640x0"
            ),
            MyPost(
                id: "004",
                authorId: "002",
                author: "милые жвётние",
               
                description: "❤️",
                likes: 64,
                views: 410,
                isExpanded: false,
                isLiked: false,
                isFavorite: false,
                createdAt: makeDate(year: 2026, month: 07, day: 8, hour: 18, minute: 19),
                authorAvatarPath: "https://sun9-26.userapi.com/s/v1/ig2/ALbWj0GmSeqgVHaJKxSt_IrgecBFYrba3m2E4dO5XBfdvmn_f0by50QaO5bGh2pbggQ0DOKOGa9pduYWIHMjFi6Z.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080&from=bu&u=ShMaiybA28_P-16pq_1dK-6o7MsWpLoj48wJBarQIro&cs=1080x0",
                imagePath: "https://sun9-46.userapi.com/s/v1/ig2/eF2-g6FJcE3H9SqhzZEq4o_REUlTrvjpwWZY8X_HM87tlA76d-XrFITRpg51qHEjlgyhpbebZG44cvhMDKFYaOfI.jpg?quality=95&as=32x42,48x63,72x95,108x142,160x211,240x317,360x475,480x633,540x712,640x844,720x950,1080x1425&from=bu&u=Z7KC65zlvO7hbejGabZNDB5ju5k1iM7_hLpuMltaTgU&cs=1080x0"
            ),
            MyPost(
                id: "005",
                authorId: "002",
                author: "милые жвётние",
               
                description: "",
                likes: 72,
                views: 450,
                isExpanded: false,
                isLiked: false,
                isFavorite: false,
                createdAt: makeDate(year: 2026, month: 07, day: 12, hour: 15, minute: 11),
                authorAvatarPath: "https://sun9-26.userapi.com/s/v1/ig2/ALbWj0GmSeqgVHaJKxSt_IrgecBFYrba3m2E4dO5XBfdvmn_f0by50QaO5bGh2pbggQ0DOKOGa9pduYWIHMjFi6Z.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080&from=bu&u=ShMaiybA28_P-16pq_1dK-6o7MsWpLoj48wJBarQIro&cs=1080x0",
                imagePath: "https://sun9-49.userapi.com/s/v1/ig2/cbIdoJMrUC90GuUWysMFHcH6Qb7zfenYUugJ1aA1MnPN2tbQWySGe0_dRdr_QEZ-PQ3xbh6jFpp7h0UqDPWYAtR0.jpg?quality=95&as=32x40,48x60,72x90,108x135,160x200,240x300,360x450,480x600,540x675,640x800,720x900,1080x1350&from=bu&u=pu4e8YU4r2epv6lfES3QeY50q3OGCu92f9woStDqkzQ&cs=1080x0"
            ),
            MyPost(
                id: "006",
                authorId: "003",
                author: "Программирование",
              
                description: "",
                likes: 74,
                views: 456,
                isExpanded: false,
                isLiked: false,
                isFavorite: false,
                createdAt: makeDate(year: 2026, month: 06, day: 25, hour: 12, minute: 16),
                authorAvatarPath: "https://sun1-28.userapi.com/impg/c846520/v846520871/6cb2e/ve1cqPZF5y4.jpg?size=512x512&quality=96&sign=9709100bb90cd5e6b3f756bd1a6d3df3&type=album",
                imagePath: "https://sun9-23.userapi.com/s/v1/ig2/hjn08Fe3ExCUjP2-FA4Q6iy5AC1a9NVt7Q3SxA2fWJT0kEf5OITMikVWnrTCGn-QsGl2GhiyJExU6IFreBH-cryA.jpg?quality=95&crop=0,0,1144,1279&as=32x36,48x54,72x80,108x121,160x179,240x268,360x402,480x537,540x604,640x716,720x805,1080x1207,1144x1279&from=bu&u=oySYdHpL9gWcHcdCb8_mpnLmQvbdIAUua7Rfmh4em38&cs=1144x0"
            ),
            MyPost(
                id: "007",
                authorId: "004",
                author: "Программирование / itProger",
               
                description: "",
                likes: 84,
                views: 487,
                isExpanded: false,
                isLiked: false,
                isFavorite: false,
                createdAt: makeDate(year: 2026, month: 07, day: 9, hour: 20, minute: 32),
                authorAvatarPath: "https://sun9-82.userapi.com/s/v1/ig1/49IXwqd9hWYNT475Wk9Bh06FAlxBgDxtZ0lGki0PjXg9GgsEHT2DpHYNFnCQh8ILhi2xTYFh.jpg?quality=96&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,512x512&from=bu&u=Jns9W4iHlAXbWDFm6N94on6wWyjzNJDT5VT_fjPhaHM&cs=512x0",
                imagePath: "https://sun9-27.userapi.com/s/v1/ig2/Qaf6komS7rcCaFsILj_ZUQCUvQ_MHRwv3ig5B-P6jMA7tUKKSsJCnEJ5fNpRutAv40fT-04aPF9WOAmQSJwYwA1p.jpg?quality=96&as=32x30,48x45,72x67,108x101,160x149,240x223,360x335,480x447,540x503,640x596,720x670,1080x1006,1280x1192&from=bu&u=OCXjV0blz7Eu0z02_SL3RlvOUyKwkOlR9MZaTi5_uB0&cs=640x0"
            ),
            MyPost(
                id: "008",
                authorId: "005",
                author: "Находки на Wildberries",
               
                description: "Подборка обуви с WB",
                likes: 84,
                views: 467,
                isExpanded: false,
                isLiked: false,
                isFavorite: false,
                createdAt: makeDate(year: 2026, month: 07, day: 5, hour: 11, minute: 45),
                authorAvatarPath: "https://sun9-35.userapi.com/s/v1/ig2/xB5DkjWhICapYaIysrNIgQrLSToIrG6rSoiKcE0efGZIY79kFm0Ik7z5QQMWjoYIAbg5FiFui0mtxbJFTHfcHGsM.jpg?quality=95&as=32x43,48x64,72x96,108x144,160x213,240x320,360x479,480x639,540x719,564x751&from=bu&u=x2r3O4GgrsYwe4BEsJZik3wiUc44Y3JLdW-QZVc_XR0&cs=564x0",
                imagePath: "https://sun9-75.userapi.com/s/v1/ig2/A0F8Ls0MUhbZ-5y1NDYXdpc223v3VWZXSndtqpY-Pl-sFlJnjz6MVGl7i4Nu7foiPGYazKDKDv-egLkZS2PlgjBF.jpg?quality=95&as=32x40,48x60,72x90,108x135,160x200,240x300,360x450,480x600,540x675,640x800,720x900,1080x1350&from=bu&u=ecX2OmBsPQ3fgqMdRLf0jgHY3AroDqwZvZxJFfqREfs&cs=1080x0"
            ),
            
            
            MyPost(
                id: "009",
                authorId: "004",
                author: "Программирование / itProger",
               
                description: "",
                likes: 72,
                views: 543,
                isExpanded: false,
                isLiked: false,
                isFavorite: false,
                createdAt: makeDate(year: 2026, month: 07, day: 4, hour: 9, minute: 0),
                authorAvatarPath: "https://sun9-82.userapi.com/s/v1/ig1/49IXwqd9hWYNT475Wk9Bh06FAlxBgDxtZ0lGki0PjXg9GgsEHT2DpHYNFnCQh8ILhi2xTYFh.jpg?quality=96&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,512x512&from=bu&u=Jns9W4iHlAXbWDFm6N94on6wWyjzNJDT5VT_fjPhaHM&cs=512x0",
                imagePath: "https://sun9-77.userapi.com/s/v1/ig2/R8Jvi-MpjAYHDankLtn2LQCcR8gft7BA3XowB0UsFinPlVcA23TT61jNDPYSincp8YueV7aLGCOThKFQoJUQEifA.jpg?quality=96&as=32x40,48x60,72x90,108x135,160x200,240x300,360x450,480x600,540x675,640x800,720x900,1080x1350&from=bu&u=ghhCI7arleBCEX0SRGn4Tcq-D_gInk_j_RFQMzI8nek&cs=1080x0"
            ),
            
            MyPost(
                id: "010",
                authorId: "002",
                author: "милые жвётние",
               
                description: "",
                likes: 85,
                views: 562,
                isExpanded: false,
                isLiked: false,
                isFavorite: false,
                createdAt: makeDate(year: 2026, month: 07, day: 6, hour: 8, minute: 8),
                authorAvatarPath: "https://sun9-26.userapi.com/s/v1/ig2/ALbWj0GmSeqgVHaJKxSt_IrgecBFYrba3m2E4dO5XBfdvmn_f0by50QaO5bGh2pbggQ0DOKOGa9pduYWIHMjFi6Z.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080&from=bu&u=ShMaiybA28_P-16pq_1dK-6o7MsWpLoj48wJBarQIro&cs=1080x0",
                imagePath:
                    "https://sun9-64.userapi.com/s/v1/ig2/KVtZZvABuXpqDHlmAw2AhxcDtckPrmK3rDbWEcxI7px50l-ChT8klX_PDg9z7YgyaulbVcxMjpIGzLZwO0-us207.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080&from=bu&u=XH5PP8lxKcvO3hDdPiurA8fZLkdkYnSUkwwQPbXTnig&cs=640x0"
                
            ),
            MyPost(
                id: "011",
                authorId: "001",
                author: "Swift | SwiftUI | iOS Сообщество разработчиков",
               
                description: """
                    Подготовили для вас небольшую шпаргалку по стандартным шрифтам xCode:

                    👉 название
                    👉 высота
                    👉 как выглядит на iPhone 17 pro

                    Не благодарите)
                    """,
                likes: 98,
                views: 589,
                isExpanded: false,
                isLiked: false,
                isFavorite: false,
                createdAt: makeDate(year: 2026, month: 07, day: 7, hour: 11, minute: 8),
                authorAvatarPath: "https://sun9-42.userapi.com/s/v1/ig2/le0Rkuizz88qInuhH-jLZ7D7txeEbc1s-pRA06qZPnX7UjXFZBVmpAIDXJYPRTgVmMr5JToqic80vZasH3SSbDRA.jpg?quality=95&as=32x35,48x52,72x78,108x117,160x174,240x261,360x391,480x521,540x586,640x695,720x782,1024x1112&from=bu&u=c8MY7mKehpgMln3hsfK1CmZQ2eyrV1sWzgAJT9AkuOs&cs=1024x0",
                imagePath:
                    "https://sun9-80.userapi.com/s/v1/ig2/F325ynvbu5arvQvjQ3Bgmp0BaebwX8cDsL6dXCWWOA4iMviwEPvVFPMFWz44rDCUHL3RuOF4Y0tGNfqjId79Qe9R.jpg?quality=95&crop=0,40,669,1003&as=32x48,48x72,72x108,108x162,160x240,240x360,360x540,480x720,540x810,640x960,669x1003&from=bu&u=J4FyVaZC9JzerucH4BZGhspy3bkxtcZFbYfRD6NqgO8&cs=669x0"
                
            )
        ]
    }
    
    /// Вспомогательный метод для создания Date из компонентов.
    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0
    ) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        return calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ))!
    }

    /// Эмуляция сетевого запроса ленты
    func fetchFeed(for userId: String) async throws -> [MyPost] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return posts.sorted { $0.createdAt > $1.createdAt }
    }

    /// Установить или снять лайк у поста
    func setLike(_ isLiked: Bool, for postId: String) async throws {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }

        var post = posts[index]
        if post.isLiked == isLiked { return }
        // Обновить флаг и количество лайков
        post.isLiked = isLiked
        post.likes += isLiked ? 1 : -1
        posts[index] = post
    }

    /// Обновить количество просмотров поста
    func updateViews(id: String, views: Int) async throws {
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return }

        var post = posts[index]
        post.views = views
        posts[index] = post
    }
}
