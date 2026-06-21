import CoreData
import Foundation

/// Протокол кеш‑хранилища пользователя (для тестов).
protocol UserCacheStoreProtocol: AnyObject {
    func save(_ user: User) throws
    func load(userID: String) throws -> User?
}

/// Сервис для кеширования доменной модели `User` в Core Data.
final class UserCacheStore: UserCacheStoreProtocol {
    
    /// Core Data‑стек (общий singleton).
    private let stack: CoreDataStack
    
    /// Основной (UI) контекст.
    private var viewContext: NSManagedObjectContext {
        stack.viewContext
    }
    
    /// Имя сущности в модели Core Data.
    private let entityName = "CDUser"
    
    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }
    
    /// Сохранить (обновить) данные пользователя в кеше.
    func save(_ user: User) throws {
        // Фоновый контекст для записи
        let context = stack.newBackgroundContext()
        
        try context.performAndWait {
            // Поиск существующего CDUser по id
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            request.predicate = NSPredicate(format: "id == %@", user.id)
            request.fetchLimit = 1
            
            let cdUser: NSManagedObject
            if let existing = try context.fetch(request).first {
                // Если запись есть - обновить
                cdUser = existing
            } else {
                // Записи нет — создать новую
                guard let entity = NSEntityDescription.entity(
                    forEntityName: entityName,
                    in: context
                ) else {
                    throw AppError.cache(
                        message: "Entity \(entityName) not found in model"
                    )
                }
                cdUser = NSManagedObject(entity: entity, insertInto: context)
                // id обязателен — проставляется сразу
                cdUser.setValue(user.id, forKey: "id")
            }
            
            // Обновление остальных полей
            cdUser.setValue(user.name.firstName, forKey: "firstName")
            cdUser.setValue(user.name.lastName, forKey: "lastName")
            cdUser.setValue(user.email, forKey: "email")
            cdUser.setValue(user.phone, forKey: "phone")
            cdUser.setValue(user.city, forKey: "city")
            cdUser.setValue(user.birthDate, forKey: "birthDate")
            cdUser.setValue(user.status, forKey: "status")
            cdUser.setValue(user.avatarURL?.absoluteString, forKey: "avatarURL")
            cdUser.setValue(user.localAvatarImage != nil, forKey: "hasLocalAvatar")
            
            // Сохранить изменения, если они есть
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    /// Загрузить пользователя по id из кеша.
    func load(userID: String) throws -> User? {
        let context = viewContext
        
        // Поиск CDUser по id
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        request.predicate = NSPredicate(format: "id == %@", userID)
        request.fetchLimit = 1
        
        guard let cd = try context.fetch(request).first else {
            // В кеше ничего нет
            return nil
        }
        
        // Чтение данных из NSManagedObject
        let firstName = cd.value(forKey: "firstName") as? String ?? ""
        let lastName = cd.value(forKey: "lastName") as? String ?? ""
        let email = cd.value(forKey: "email") as? String
        let phone = cd.value(forKey: "phone") as? String
        let city = cd.value(forKey: "city") as? String
        let birthDate = cd.value(forKey: "birthDate") as? Date
        let status = cd.value(forKey: "status") as? String
        let avatarStr = cd.value(forKey: "avatarURL") as? String
        let id = cd.value(forKey: "id") as? String ?? userID
        
        // Соборка доменной модели User
        let name = Name(firstName: firstName, lastName: lastName)
        
        let user = User(
            id: id,
            nickname: nil,
            name: name,
            email: email,
            phone: phone,
            city: city,
            birthDate: birthDate,
            status: status,
            avatarURL: avatarStr.flatMap(URL.init(string:))
        )
    
        return user
    }
}
