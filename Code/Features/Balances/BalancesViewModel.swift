//
//  BalancesViewModel.swift
//  ExpenseSplitter
//
//  Bridges Core Data entities to the pure BalanceCalculator, and bridges
//  the resulting UUID-based Settlements back to display-friendly names.
//

import CoreData

struct SettlementDisplay {
    let fromName: String
    let toName: String
    let amountText: String
}

struct MemberBalanceDisplay {
    let name: String
    let amountText: String
    let isPositive: Bool
    let isSettled: Bool
}

final class BalancesViewModel {

    private let group: GroupEntity
    private let context: NSManagedObjectContext

    private(set) var memberBalances: [MemberBalanceDisplay] = []
    private(set) var settlements: [SettlementDisplay] = []

    init(group: GroupEntity, context: NSManagedObjectContext) {
        self.group = group
        self.context = context
    }

    var groupName: String {
        group.name ?? ""
    }

    var numberOfMemberBalances: Int {
        memberBalances.count
    }

    var numberOfSettlements: Int {
        settlements.count
    }

    func memberBalance(at index: Int) -> MemberBalanceDisplay {
        memberBalances[index]
    }

    func settlement(at index: Int) -> SettlementDisplay {
        settlements[index]
    }

    /// Pulls every member + expense for the group out of Core Data, converts
    /// them to the plain-value types BalanceCalculator understands, and
    /// computes balances + the simplified settle-up list.
    func calculateBalances() {
        let memberSet = (group.members as? Set<MemberEntity>) ?? []
        // Members without an id can't participate in the balance math (this
        // shouldn't happen in practice since we always assign one on
        // creation), so they're safely skipped here.
        let members = memberSet.filter { $0.id != nil }

        var nameByID: [UUID: String] = [:]
        for member in members {
            guard let id = member.id else { continue }
            nameByID[id] = member.name ?? ""
        }

        let expenseSet = (group.expenses as? Set<ExpenseEntity>) ?? []
        let expenseInputs: [ExpenseInput] = expenseSet.compactMap { expense in
            guard let payerID = asOptional(expense.paidBy)?.id else { return nil }
            let splitMembers = (expense.splitAmong as? Set<MemberEntity>) ?? []
            let splitIDs = splitMembers.compactMap { $0.id }
            guard !splitIDs.isEmpty else { return nil }
            return ExpenseInput(amount: expense.amount, paidByID: payerID, splitAmongIDs: splitIDs)
        }

        let memberIDs = members.compactMap { $0.id }
        let balances = BalanceCalculator.netBalances(memberIDs: memberIDs, expenses: expenseInputs)
        let rawSettlements = BalanceCalculator.settleUp(balances: balances)

        memberBalances = members
            .sorted { ($0.name ?? "") < ($1.name ?? "") }
            .compactMap { member -> MemberBalanceDisplay? in
                guard let id = member.id else { return nil }
                let amount = balances[id] ?? 0
                return MemberBalanceDisplay(
                    name: member.name ?? "",
                    amountText: CurrencyFormatter.signedString(from: amount),
                    isPositive: amount > BalanceCalculator.epsilon,
                    isSettled: abs(amount) <= BalanceCalculator.epsilon
                )
            }

        settlements = rawSettlements.map { settlement in
            SettlementDisplay(
                fromName: nameByID[settlement.fromID] ?? "Unknown",
                toName: nameByID[settlement.toID] ?? "Unknown",
                amountText: CurrencyFormatter.string(from: settlement.amount)
            )
        }
    }
}
