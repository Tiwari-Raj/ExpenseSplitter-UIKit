//
//  AddExpenseViewModel.swift
//  ExpenseSplitter
//

import CoreData

final class AddExpenseViewModel {

    private let group: GroupEntity
    private let context: NSManagedObjectContext

    /// All members of the group, in a stable sorted order.
    let members: [MemberEntity]

    /// Index of the currently-selected "paid by" member.
    private(set) var paidByIndex: Int = 0

    /// Which member indices are currently checked for "split among".
    private(set) var splitAmongIndices: Set<Int> = []

    init(group: GroupEntity, context: NSManagedObjectContext) {
        self.group = group
        self.context = context
        let set = (group.members as? Set<MemberEntity>) ?? []
        self.members = set.sorted { ($0.name ?? "") < ($1.name ?? "") }
        // By default, split the expense among everyone.
        self.splitAmongIndices = Set(0..<members.count)
    }

    var numberOfMembers: Int {
        members.count
    }

    func memberName(at index: Int) -> String {
        members[index].name ?? ""
    }

    func isSplitSelected(at index: Int) -> Bool {
        splitAmongIndices.contains(index)
    }

    func toggleSplit(at index: Int) {
        if splitAmongIndices.contains(index) {
            splitAmongIndices.remove(index)
        } else {
            splitAmongIndices.insert(index)
        }
    }

    func selectPaidBy(index: Int) {
        paidByIndex = index
    }

    enum ValidationError: LocalizedError {
        case emptyDescription
        case invalidAmount
        case noSplitMembers

        var errorDescription: String? {
            switch self {
            case .emptyDescription:
                return "Please enter a description for this expense."
            case .invalidAmount:
                return "Please enter a valid amount greater than zero."
            case .noSplitMembers:
                return "Select at least one person to split this expense among."
            }
        }
    }

    /// Creates and saves the ExpenseEntity.
    @discardableResult
    func saveExpense(description rawDescription: String, amountText: String) -> Result<ExpenseEntity, ValidationError> {
        let description = rawDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !description.isEmpty else { return .failure(.emptyDescription) }

        guard let amount = CurrencyFormatter.amount(from: amountText), amount > 0 else {
            return .failure(.invalidAmount)
        }

        guard !splitAmongIndices.isEmpty, !members.isEmpty else {
            return .failure(.noSplitMembers)
        }

        let expense = ExpenseEntity(context: context)
        expense.id = UUID()
        expense.desc = description
        expense.amount = amount
        expense.date = Date()
        expense.group = group
        expense.paidBy = members[paidByIndex]

        let splitMembers = splitAmongIndices.sorted().map { members[$0] }
        expense.splitAmong = NSSet(array: splitMembers)

        do {
            try context.save()
            return .success(expense)
        } catch {
            assertionFailure("Failed to save expense: \(error)")
            context.rollback()
            return .failure(.invalidAmount)
        }
    }
}
