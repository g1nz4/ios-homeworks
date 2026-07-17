import UIKit
import CoreData
import Foundation

/// Протокол кеш‑хранилища пользователя (для тестов).
protocol CDUserCacheProtocol: AnyObject {
    func save(_ user: User) async throws
    func load(userID: String) async throws -> User?
}

/// Сервис для кеширования доменной модели `User` в Core Data.
final class CDUserCache: CDUserCacheProtocol {
    
    /// Core Data‑стек (общий singleton).
    private let stack = CoreDataStack.shared
    
    /// Имя сущности в модели Core Data.
    private let entityName = "CDUser"
    
    /// Сохранить (обновить) данные пользователя в кеше.
    func save(_ user: User) async throws {
        // Фоновый контекст для записи
        let context = stack.newBackgroundContext()
        
        try await context.perform {
            // Поиск существующего CDUser по id
            let request = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
            request.predicate = NSPredicate(format: "id == %@", user.id)
            request.fetchLimit = 1
            
            let cdUser: NSManagedObject
            if let existing = try context.fetch(request).first {
                // Если запись есть - обновить
                cdUser = existing
            } else {
                // Записи нет — создать новую
                guard let entity = NSEntityDescription.entity(
                    forEntityName: self.entityName,
                    in: context
                ) else {
                    throw AppError.cache(
                        message: "Entity \(self.entityName) not found in model"
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
            cdUser.setValue(user.coverURL?.absoluteString, forKey: "coverURL")
            cdUser.setValue(user.subscribersCount.map { NSNumber(value: $0) }, forKey: "subscribersCount")
            cdUser.setValue(user.friendsCount.map { NSNumber(value: $0) }, forKey: "friendsCount")
            cdUser.setValue(user.followingCount.map { NSNumber(value: $0) }, forKey: "followingCount")
            cdUser.setValue(user.gender.rawValue, forKey: "gender")
            cdUser.setValue(user.isOnline, forKey: "isOnline")

            // Сохранить изменения, если они есть
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    /// Загрузить пользователя по id из кеша.
    func load(userID: String) async throws -> User? {
        let context = stack.newBackgroundContext()
        
        return try await context.perform { () -> User? in
            // Поиск CDUser по id
            let request = NSFetchRequest<NSManagedObject>(entityName: self.entityName)
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
            let coverStr = cd.value(forKey: "coverURL")  as? String
            
            let subs = (cd.value(forKey: "subscribersCount") as? NSNumber)?.intValue
            let friends = (cd.value(forKey: "friendsCount") as? NSNumber)?.intValue
            let following = (cd.value(forKey: "followingCount") as? NSNumber)?.intValue
            
            let id = cd.value(forKey: "id") as? String ?? userID
            
            let genderStr = cd.value(forKey: "gender") as? String ?? "other"
            let isOnline = cd.value(forKey: "isOnline") as? Bool ?? false
            let genderEnum = Gender(rawValue: genderStr) ?? .male
            
            // Сборка доменной модели User
            let name = Name(firstName: firstName, lastName: lastName)
            
            let avatarURL = avatarStr.flatMap { URL(string: $0) }
            let coverURL = coverStr.flatMap { URL(string: $0) }
            
            let user = User(
                id: id,
                nickname: nil,
                name: name,
                gender: genderEnum,
                email: email,
                phone: phone,
                city: city,
                birthDate: birthDate,
                status: status,
                avatarURL: avatarURL,
                coverURL: coverURL,
                subscribersCount: subs,
                friendsCount: friends,
                followingCount: following,
                isOnline: isOnline
            )
            
            return user
        }
    }
}
