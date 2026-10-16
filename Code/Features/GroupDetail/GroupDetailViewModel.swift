//
//  GroupDetailViewModel.swift
//  ExpenseSplitter
//

import CoreData

struct ExpenseSummary {
    let objectID: NSManagedObjectID
    let description: String
    let amount: Double
    let date: Date
    let paidByName: String
}

protocol GroupDetailViewModelDelegate: AnyObject {
    func groupDetailDidUpdate()
}

final class GroupDetailViewModel {

    weak var delegate: GroupDetailViewModelDelegate?

    let group: GroupEntity
    private let context: NSManagedObjectContext

    private(set) var expenses: [ExpenseSummary] = []

    init(group: GroupEntity, context: NSManagedObjectContext) {
        self.group = group
        self.context = context
    }

    var groupName: String {
        group.name ?? ""
    }

    var numberOfExpenses: Int {
        expenses.count
    }

    var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var members: [MemberEntity] {
        let set = (group.members as? Set<MemberEntity>) ?? []
        return set.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    func expense(at index: Int) -> ExpenseSummary {
        expenses[index]
    }

    func managedExpense(at index: Int) -> ExpenseEntity? {
        try? context.existingObject(with: expenses[index].objectID) as? ExpenseEntity
    }

    func loadExpenses() {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            let results = try context.fetch(request)
            expenses = results.map {
                ExpenseSummary(
                    objectID: $0.objectID,
                    description: $0.desc ?? "",
                    amount: $0.amount,
                    date: $0.date ?? Date(),
                    paidByName: asOptional($0.paidBy)?.name ?? "Unknown"
                )
            }
        } catch {
            assertionFailure("Failed to fetch expenses: \(error)")
            expenses = []
        }

        delegate?.groupDetailDidUpdate()
    }

    func deleteExpense(at index: Int) {
        guard let entity = managedExpense(at: index) else { return }
        context.delete(entity)
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to delete expense: \(error)")
        }
        loadExpenses()
    }
}
