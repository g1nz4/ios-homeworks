import Foundation
import CoreData

struct LoadedStory {
    let items: [Data]
    let createdAt: Date?
}

protocol CDStoryStorageProtocol {
    func save(imageDatas: [Data], duration: TimeInterval, for userId: String) async throws
    func loadLastStory(for userId: String) async throws -> LoadedStory?
}


final class CDStoryStorage: CDStoryStorageProtocol {

    private let stack = CoreDataStack.shared

    func save(imageDatas: [Data], duration: TimeInterval, for userId: String) async throws {
        guard !imageDatas.isEmpty else { return }
        
        let context = stack.newBackgroundContext()
        
        try await context.perform {
            
            let userRequest: NSFetchRequest<CDUser> = CDUser.fetchRequest()
            userRequest.predicate = NSPredicate(format: "id == %@", userId)
            userRequest.fetchLimit = 1
            
            guard let user = try context.fetch(userRequest).first else {
               
                return
            }
            
            
            let story = CDStory(context: context)
            story.id = UUID()
            story.createdAt = Date()
            story.user = user
            
            var items: [CDStoryItem] = []
            
            for (index, data) in imageDatas.enumerated() {
                let item = CDStoryItem(context: context)
                item.id = UUID()
                item.order = Int32(index)
                item.duration = duration
                item.imageData = data
                item.story = story
                items.append(item)
            }
            
            
            story.items = NSSet(array: items)
            
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    func loadLastStory(for userId: String) async throws -> LoadedStory? {
        let context = stack.newBackgroundContext()

        return try await context.perform {
            let request: NSFetchRequest<CDStory> = CDStory.fetchRequest()
            request.predicate = NSPredicate(format: "user.id == %@", userId)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            request.fetchLimit = 1

            guard let story = try context.fetch(request).first else {
                return nil
            }

            guard let set = story.items as? Set<CDStoryItem> else {
                return nil
            }

            let sortedItems = set.sorted { $0.order < $1.order }
            let datas = sortedItems.compactMap { $0.imageData }

            return LoadedStory(items: datas, createdAt: story.createdAt)
        }
    }
}

