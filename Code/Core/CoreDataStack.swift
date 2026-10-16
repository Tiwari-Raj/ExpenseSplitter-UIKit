//
//  CoreDataStack.swift
//  ExpenseSplitter
//
//  Thin wrapper around NSPersistentContainer. Everything in the app
//  reads/writes through CoreDataStack.shared.
//

import CoreData

final class CoreDataStack {

    static let shared = CoreDataStack()

    /// Pass `inMemory: true` to get a throwaway store, handy for previews/tests.
    private init(inMemory: Bool = false) {
        persistentContainer = NSPersistentContainer(name: "ExpenseSplitter")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            persistentContainer.persistentStoreDescriptions = [description]
        }

        persistentContainer.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In a production app this would be surfaced to the user /
                // logged to a crash reporter rather than crashing outright,
                // but a failed store load during development should be loud.
                fatalError("Unresolved Core Data error: \(error), \(error.userInfo)")
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Creates a stack backed by an in-memory store. Useful for SwiftUI
    /// previews or unit tests that need a real NSManagedObjectContext
    /// without touching disk.
    static func makeInMemoryStack() -> CoreDataStack {
        CoreDataStack(inMemory: true)
    }

    let persistentContainer: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    /// Saves the view context if it has uncommitted changes.
    func saveContext() {
        let context = viewContext
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved Core Data save error: \(nserror), \(nserror.userInfo)")
        }
    }

    /// Creates a private background context for heavier writes, if ever needed.
    func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
}
