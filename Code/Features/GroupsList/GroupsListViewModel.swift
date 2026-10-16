//
//  GroupsListViewModel.swift
//  ExpenseSplitter
//

import CoreData

/// Lightweight, Core-Data-free representation of a group for display.
struct GroupSummary {
    let objectID: NSManagedObjectID
    let name: String
    let dateCreated: Date
    let memberCount: Int
    let totalSpent: Double
}

protocol GroupsListViewModelDelegate: AnyObject {
    func groupsListDidUpdate()
}

final class GroupsListViewModel {

    weak var delegate: GroupsListViewModelDelegate?

    private(set) var groups: [GroupSummary] = []

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    var numberOfGroups: Int {
        groups.count
    }

    func group(at index: Int) -> GroupSummary {
        groups[index]
    }

    /// Re-fetches all groups from Core Data, newest first.
    func loadGroups() {
        let request: NSFetchRequest<GroupEntity> = GroupEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]

        do {
            let results = try context.fetch(request)
            groups = results.map { entity in
                let expenses = (entity.expenses as? Set<ExpenseEntity>) ?? []
                let members = (entity.members as? Set<MemberEntity>) ?? []
                let total = expenses.reduce(0.0) { $0 + $1.amount }
                return GroupSummary(
                    objectID: entity.objectID,
                    // `??` works whether these Core Data properties were
                    // generated as optional or non-optional, so this compiles
                    // either way and never force-unwraps.
                    name: entity.name ?? "",
                    dateCreated: entity.dateCreated ?? Date(),
                    memberCount: members.count,
                    totalSpent: total
                )
            }
        } catch {
            assertionFailure("Failed to fetch groups: \(error)")
            groups = []
        }

        delegate?.groupsListDidUpdate()
    }

    /// Deletes the group at the given index (used by swipe-to-delete).
    func deleteGroup(at index: Int) {
        let summary = groups[index]
        guard let entity = try? context.existingObject(with: summary.objectID) else { return }
        context.delete(entity)
        saveAndReload()
    }

    func managedGroup(at index: Int) -> GroupEntity? {
        try? context.existingObject(with: groups[index].objectID) as? GroupEntity
    }

    private func saveAndReload() {
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save after deleting group: \(error)")
        }
        loadGroups()
    }
}
