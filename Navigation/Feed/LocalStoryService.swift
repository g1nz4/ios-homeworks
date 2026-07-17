import Foundation

/// Один слайд внутри сторис
struct FeedStoryItem: Identifiable, Hashable {
    let id: String            // ID слайда
    let imageURL: String      // URL изображения для этого слайда
}

/// Модель сторис (автор + набор слайдов)
struct FeedStory: Identifiable, Hashable {
    let id: String                   // ID сторис/автора
    let authorName: String           // Имя автора для отображения
    let avatarURL: String            // URL аватарки автора

    /// URL, который показываем как превью сторис:
    /// если есть items — берём первую картинку, иначе — avatarURL.
    var avatarURLForDisplay: String {
        items.first?.imageURL ?? avatarURL
    }

    let createdAt: Date             // Время создания сторис
    var isViewed: Bool              // Флаг "просмотрено"
    var items: [FeedStoryItem]      // Слайды сторис
}

/// Протокол сервиса сторис (без сохранения в CoreData, только локальные данные).
protocol LocalStoryServiceProtocol: AnyObject {
    /// Сторис для экрана ленты (локальный источник).
    func fetchStories(for userId: String) async throws -> [FeedStory]
}

/// Локальный сервис сторис, хранит данные в памяти и имитирует сеть.
final class LocalStoryService: LocalStoryServiceProtocol {

    /// Массив сторис в памяти
    private var stories: [FeedStory] = []

    init() {
        seedStories()
    }

    /// Заполннение сторис тестовыми данными
    private func seedStories() {
        stories = [
            FeedStory(
                id: "001",
                authorName: "Находки на Wildberries",
                avatarURL: "https://sun9-13.userapi.com/s/v1/ig2/h362rfwwMLIhpPkwS7utdJ2ogBLA3yInDWD-X4YpAhjMt6yAAmAQCzq8IK1wOp4A9ExZNNTIu3G_e7rKFgZpjNdJ.jpg?quality=95&as=32x43,48x64,72x96,108x144,160x213,240x320,360x480,480x640,540x720,640x853,720x960,1080x1440&from=bu&u=l7rSiNom57lkIlC8eCvzbOZhD3DjxAOjY4kQZu2lz-4&cs=1080x0",
                createdAt: makeDate(year: 2026, month: 07, day: 13, hour: 16, minute: 38),
                isViewed: false,
                items: [
                    FeedStoryItem(
                        id: "001_1",
                        imageURL: "https://sun9-13.userapi.com/s/v1/ig2/h362rfwwMLIhpPkwS7utdJ2ogBLA3yInDWD-X4YpAhjMt6yAAmAQCzq8IK1wOp4A9ExZNNTIu3G_e7rKFgZpjNdJ.jpg?quality=95&as=32x43,48x64,72x96,108x144,160x213,240x320,360x480,480x640,540x720,640x853,720x960,1080x1440&from=bu&u=l7rSiNom57lkIlC8eCvzbOZhD3DjxAOjY4kQZu2lz-4&cs=1080x0"
                        
                    ),
                    FeedStoryItem(
                        id: "001_2",
                        imageURL: "https://sun9-77.userapi.com/s/v1/ig2/SoH8RtjPmYWgdEUwpNxmm_-WSwys1kIPpR-MGKcic4mIhbzlNtdCMRvicjHHtmSfGvHUm5i3EJOSShsNeVUjnKut.jpg?quality=95&as=32x43,48x64,72x96,108x143,160x213,240x319,360x478,480x638,540x717,640x850,720x957,1080x1435,1280x1701,1284x1706&from=bu&cs=1280x0"
                        
                    ),
                    FeedStoryItem(
                        id: "001_3",
                        imageURL: "https://sun9-10.userapi.com/s/v1/ig2/kBOG8o3_QcbTrNTf4vviZg89dB0r-9KVQWxFHoPOs-qzj0hGqTegV27BcHGtOrpOHyAjdeX7joBmdtW2Fs0kAZMx.jpg?quality=95&as=32x43,48x64,72x96,108x143,160x213,240x319,360x478,480x638,540x717,640x850,720x957,1080x1435,1280x1701,1284x1706&from=bu&cs=1280x0"
                        
                    ),
                    FeedStoryItem(
                        id: "001_4",
                        imageURL: "https://sun9-61.userapi.com/s/v1/ig2/pMfypOunkVMynmaQr2pPKPX7BPTjcPReOzE2c-5nwZSMf-Uj6Juv12_7V_BPnAumjck6d9Ar_7AQkeAsRahooIvg.jpg?quality=95&as=32x43,48x64,72x96,108x143,160x213,240x319,360x478,480x638,540x717,640x850,720x957,1080x1435,1280x1701,1284x1706&from=bu&cs=1280x0"
                        
                    ),
                    FeedStoryItem(
                        id: "001_5",
                        imageURL: "https://sun9-69.userapi.com/s/v1/ig2/kGkJGs7YuqJ1uOyLqZ5Lo8ecxpdMfqJhVttbpLagzmqnatJDqZNej611avg2bm6IgmdvKEiaDkiQejpxxzjtTFQG.jpg?quality=95&as=32x43,48x64,72x96,108x143,160x213,240x319,360x478,480x638,540x717,640x850,720x957,1080x1435,1280x1701,1284x1706&from=bu&cs=1280x0"
                        
                    ),
                    FeedStoryItem(
                        id: "001_6",
                        imageURL: "https://sun9-82.userapi.com/s/v1/ig2/JxinJhER9eYu1MzCqYVl_BsWdG3D6GJy4pQhxyzakkq4yNy4gF_lb41D_yQgvaWaCCTatgX9UZsVg-6e5joNhj6Q.jpg?quality=95&as=32x43,48x64,72x96,108x143,160x213,240x319,360x478,480x638,540x717,640x850,720x957,1080x1435,1280x1701,1284x1706&from=bu&cs=1280x0"
                        
                    ),
                    FeedStoryItem(
                        id: "001_7",
                        imageURL: "https://sun9-42.userapi.com/s/v1/ig2/6J_LbCIKbuX7m5-l8YxGhjXlMLj3KNaKNKBxpqiM43xBkxIUIpAFrTo61_6VekJfZynatfO2fBkWWV9iWS0N2A7O.jpg?quality=95&as=32x43,48x64,72x96,108x143,160x213,240x319,360x478,480x638,540x717,640x850,720x957,1080x1435,1280x1701,1284x1706&from=bu&cs=1280x0"
                        
                    ),
                ]
            ),
            FeedStory(
                id: "002",
                authorName: "Программирование / itProger",
                avatarURL: "https://sun9-82.userapi.com/s/v1/ig1/49IXwqd9hWYNT475Wk9Bh06FAlxBgDxtZ0lGki0PjXg9GgsEHT2DpHYNFnCQh8ILhi2xTYFh.jpg?quality=96&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,512x512&from=bu&u=Jns9W4iHlAXbWDFm6N94on6wWyjzNJDT5VT_fjPhaHM&cs=512x0",
                createdAt: makeDate(year: 2026, month: 07, day: 12, hour: 10, minute: 18),
                isViewed: false,
                items: [
                    FeedStoryItem(
                        id: "002_1",
                        imageURL: "https://sun9-20.userapi.com/s/v1/ig2/_fj6Rmx5W9SugfCUVYgcF3NPz6rEhRrz3Z4RB0miLspQKOJzOqVBNcwHGNJQ24xYYtaJWhi_01cY-wBqYtARa17k.jpg?quality=95&as=32x40,48x60,72x90,108x135,160x200,240x300,360x450,480x600,540x675,640x800,720x900,1080x1350&from=bu&u=i7oB4sZPY-s1iQdgcdvuXud5JEbol1fRJDFTAlYPjb4&cs=1080x0"
                        
                    ),
                    FeedStoryItem(
                        id: "002_2",
                        imageURL: "https://sun9-32.userapi.com/s/v1/ig2/GGC_HpQN_t6Y5RhYHpXhb_bzyIafN2TKVC7T3hwmjvQEHaMcNssLTkIGHNkhVFa0Ne4cjpkqcujgW80dKjA0EjYk.jpg?quality=95&as=32x40,48x60,72x90,108x135,160x200,240x300,360x450,480x600,540x675,640x800,720x900,1080x1350&from=bu&cs=1080x0"
                        
                    ),
                    FeedStoryItem(
                        id: "002_3",
                        imageURL: "https://sun9-79.userapi.com/s/v1/ig2/5JdocgzWVxbIg95RxT3DqPPZSiZzS3EU3KjoJU8mhrPVUX0yHmxgsOlcYXSUPzyXvTRNZZKBLB3YNASuNW-Z_HTA.jpg?quality=95&as=32x40,48x60,72x90,108x135,160x200,240x300,360x450,480x600,540x675,640x800,720x900,1080x1350&from=bu&cs=1080x0"
                        
                    ),
                    FeedStoryItem(
                        id: "002_4",
                        imageURL: "https://sun9-49.userapi.com/s/v1/ig2/TDBKrYC53T0OtUPBvG8XHbPQ4ALiamrUsVwh4UsSAG_CPThWY6B894iB7DIN_4wEe5qS1hsRnVo2WZCLpfReUI9y.jpg?quality=95&as=32x40,48x60,72x90,108x135,160x200,240x300,360x450,480x600,540x675,640x800,720x900,1080x1350&from=bu&cs=1080x0"
                        
                    ),
                    FeedStoryItem(
                        id: "002_5",
                        imageURL: "https://sun9-21.userapi.com/s/v1/ig2/jZ9fjWeU90G8_NQce8i833eIR9_y6bFIJWLUE62a3UEpcuRTKIOF8zGLG3AuWjZltbrxeBwifOND8_KPssZIsITg.jpg?quality=95&as=32x40,48x60,72x90,108x135,160x200,240x300,360x450,480x600,540x675,640x800,720x900,1080x1350&from=bu&cs=1080x0"
                        
                    ),
                    FeedStoryItem(
                        id: "002_6",
                        imageURL: "https://sun9-18.userapi.com/s/v1/ig2/x7lNwg0lcCSEbRZfKd649f3JHE2lIc6yVAqNdmOFz6FHNp04H3pShLlmSrH4wxQMw0-8M2XM0zc3yA2zRZA9IQvx.jpg?quality=95&as=32x40,48x60,72x90,108x135,160x200,240x300,360x450,480x600,540x675,640x800,720x900,1080x1350&from=bu&cs=1080x0."
                        
                    ),
                    FeedStoryItem(
                        id: "002_7",
                        imageURL: "https://sun9-13.userapi.com/s/v1/ig2/pOK3o-8gcF96Y3ovXA9GKdkF9PFHU7vSYps8g0db0d5uhR1NIY8ZEvqXgrh3C9TEekWG-_ZSDDEyBGYm45vmy2gL.jpg?quality=95&as=32x40,48x60,72x90,108x135,160x200,240x300,360x450,480x600,540x675,640x800,720x900,1080x1350&from=bu&cs=1080x0"
                        
                    ),
                    FeedStoryItem(
                        id: "002_8",
                        imageURL: "https://sun9-52.userapi.com/s/v1/ig2/QbvuI7B4zFpdvf49vg1tAmwEjw9KzDH4Zxrtb_arn2kdB4EMdxXmu9zkhLBNZtdZ1Rrxs1AZfG6pV2SFioow8vkV.jpg?quality=95&as=32x40,48x60,72x90,108x135,160x200,240x300,360x450,480x600,540x675,640x800,720x900,1080x1350&from=bu&cs=1080x0"
                        
                    )
                    
                ]
            ),
            
            FeedStory(
                id: "004",
                authorName: "милые жвётние",
                avatarURL: "https://sun9-10.userapi.com/s/v1/ig2/VnV7CDaOSUQT1NtMWKx2fqNzHaDkWg4H2BwLoKE3oniuJbFMrQg5zyGY1cYqHBi2JZhUwaJpDq8Z9YsWvdtt-JgQ.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080&from=bu&u=s3_qyWOou_jwRoegaR4p8kE221StVT5OJpMZASOaGnk&cs=640x0",
                createdAt: makeDate(year: 2026, month: 07, day: 11, hour: 8, minute: 16),
                isViewed: false,
                items: [
                    FeedStoryItem(
                        id: "004_1",
                        imageURL: "https://sun9-10.userapi.com/s/v1/ig2/VnV7CDaOSUQT1NtMWKx2fqNzHaDkWg4H2BwLoKE3oniuJbFMrQg5zyGY1cYqHBi2JZhUwaJpDq8Z9YsWvdtt-JgQ.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080&from=bu&u=s3_qyWOou_jwRoegaR4p8kE221StVT5OJpMZASOaGnk&cs=640x0"
                        
                    ),
                    FeedStoryItem(
                        id: "004_2",
                        imageURL: "https://sun1-56.userapi.com/s/v1/ig2/_KnMuiSv7IEBFX_U5LVEPTDimE9_7GN4cdzwQU_2Pq1-a6TvzLYerHNBxX76SGeeq8-ElPZqA4XH3OYYeogTX8C6.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080&from=bu&u=pH_rhGw8A1429MOKCfEfPL-sAxmYXwfBtJmdNOibpXI&cs=640x0"
                        
                    ),
                    FeedStoryItem(
                        id: "004_3",
                        imageURL: "https://sun1-30.userapi.com/s/v1/ig2/hQFyF0oRWnZkLScB7dxSJ2M4FGoK4ql-5h420GbNdEyqSQKC0fyxptDTYnsoVM65690NXVG625vXNdHCMbPwz4HK.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080&from=bu&u=9Co62rR_z88Z6NVCtxhq3CL3Z6DSw5rRU6Gx9PMl2aE&cs=640x0"
                        
                    ),
                    FeedStoryItem(
                        id: "004_4",
                        imageURL: "https://sun1-99.userapi.com/s/v1/ig2/l4mFUpaUX--6H17dSr0uPHMJn1v091Xk_ALw-PP8cGJR9nNzHXR_W4lTZqa-uhV_KyLuGJj51ZT2MLEFz74Pu6pg.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080&from=bu&u=YuK3P9dKAYm5KJ7Q9A0s8I49b24Mvq4hHsKb_cf9OIg&cs=640x0"
                        
                    ),
                    FeedStoryItem(
                        id: "004_5",
                        imageURL: "https://sun9-41.userapi.com/s/v1/ig2/mizgGgrAQFvc1vEzkall3cOl_hBCX5cjCpMrSB4XlZrkpBPR-9pN-nyqhJSX8YQOAiUxKa3tTfuW_M5h0t7CcMNV.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080&from=bu&u=Ltg3kLTD_XeR6191vH_PUafVFo6BfrPeCaq5ozYCXtM&cs=640x0"
                        
                    ),
                    FeedStoryItem(
                        id: "004_6",
                        imageURL: "https://sun9-79.userapi.com/s/v1/ig2/K7pKe-3uo8p-jdyy7AMXSxOhtimLEwkx85I2nCY1D632-Vb7Acb3j5zmVp8SzhrXkm5IR2z4xlSRWNJoajiCPLgc.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080&from=bu&u=WJEdfPwd6DpU1aRirHpNareZtMwO_0SySn4vcEJvAIU&cs=640x0"
                        
                    ),
                    FeedStoryItem(
                        id: "004_7",
                        imageURL: "https://sun9-68.userapi.com/s/v1/ig2/gdRapNKDKU7ITF6hLPAerdBv_pqiDjTAU4cfwR8uZT9Mqxc-K_GZO4mwYMyABq4LkU9EZt4RljI8htBRyyM2IKZ0.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080&from=bu&u=SwBemPvS6QZQpYZRiXHotYyHFzF-Kk0aaMvtUlvgPjE&cs=640x0"
                        
                    ),
                    FeedStoryItem(
                        id: "004_8",
                        imageURL: "https://sun9-27.userapi.com/s/v1/ig2/MkF-gnX6jkQgjjmVofDf7KOFjgf77RPxMns7MUcpqc-j9kgNXgknzeT8BzwV8wW9AE8ZcYtCtlgF7lGc8XLVUwIr.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080&from=bu&u=lsuriRgEX6clTbyXExZtNHEslPbfDVPGwZfF4UwurF8&cs=640x0"
                        
                    ),
                    FeedStoryItem(
                        id: "004_9",
                        imageURL: "https://sun1-89.userapi.com/s/v1/ig2/SRbJB4jUDXmzCKlYNG9AFbP45O2Tg-Y4thU-hxPWXqCnaJV3Uwp7udWOgFhpvzM-slNXUEkUuocAWRdc-H9toYG_.jpg?quality=95&as=32x32,48x48,72x72,108x108,160x160,240x240,360x360,480x480,540x540,640x640,720x720,1080x1080&from=bu&u=CZWCpzYdkP6J_ukF93XFBqIXHxz0m34xEfIr2-fYW2Y&cs=640x0"
                        
                    )
                    
                ]
            ),
        ]
    }
    
    /// Вспомогательная функция создания даты из компонентов
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

    /// Эмуляция асинхронной загрузки сторис
    func fetchStories(for userId: String) async throws -> [FeedStory] {
        try await Task.sleep(nanoseconds: 150_000_000) // имитация сети

        // сортировка сторис
        let sortedStories = stories.sorted { $0.createdAt > $1.createdAt }

        // на всякий случай сортировка items внутри каждой сторис
        let withSortedItems = sortedStories.map { story in
            var s = story
            s.items = story.items.sorted { $0.id < $1.id }
            return s
        }

        return withSortedItems
    }

    /// Локально пометить сторис как просмотренную (в памяти)
    func markViewed(storyId: String) {
        guard let idx = stories.firstIndex(where: { $0.id == storyId }) else { return }
        stories[idx].isViewed = true
    }
}
