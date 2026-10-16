//
//  BalanceCalculator.swift
//  ExpenseSplitter
//
//  Pure, Core-Data-free balance math. Everything here operates on plain
//  Swift value types so it can be unit tested in isolation (see
//  BalanceCalculatorTests.swift) and reused from any ViewModel.
//

import Foundation

/// A Core-Data-independent snapshot of a single expense, used purely for
/// balance math. `paidByID` and `splitAmongIDs` reference member IDs.
struct ExpenseInput: Equatable {
    let amount: Double
    let paidByID: UUID
    let splitAmongIDs: [UUID]

    init(amount: Double, paidByID: UUID, splitAmongIDs: [UUID]) {
        self.amount = amount
        self.paidByID = paidByID
        self.splitAmongIDs = splitAmongIDs
    }
}

/// A single "A pays B amount X" instruction produced by the settle-up algorithm.
struct Settlement: Equatable {
    let fromID: UUID
    let toID: UUID
    let amount: Double
}

enum BalanceCalculator {

    /// The smallest amount worth treating as non-zero, to avoid floating
    /// point noise producing spurious settlements (e.g. 0.0000000001).
    static let epsilon: Double = 0.005

    /// Computes the net balance of every member across a set of expenses.
    ///
    /// For each expense, the amount is split equally among everyone in
    /// `splitAmongIDs` (including the payer, if they're part of the split).
    /// The payer's balance increases by the full amount they fronted; every
    /// member in the split (payer included) is charged their equal share.
    ///
    /// A positive result means that member is owed money overall ("net
    /// creditor"); a negative result means they owe money overall ("net
    /// debtor"). The sum of all balances is always ~0.
    ///
    /// - Parameters:
    ///   - memberIDs: every member who belongs to the group, even if they
    ///     have no expenses yet (so they still show up with a 0 balance).
    ///   - expenses: the expenses to fold into the balance.
    static func netBalances(memberIDs: [UUID], expenses: [ExpenseInput]) -> [UUID: Double] {
        var balances: [UUID: Double] = [:]
        for id in memberIDs {
            balances[id] = 0
        }

        for expense in expenses {
            guard !expense.splitAmongIDs.isEmpty else { continue }

            let shareCount = Double(expense.splitAmongIDs.count)
            let share = expense.amount / shareCount

            // Payer fronted the whole amount.
            balances[expense.paidByID, default: 0] += expense.amount

            // Everyone who shares the expense (payer included, if present
            // in the split) is charged their equal share.
            for memberID in expense.splitAmongIDs {
                balances[memberID, default: 0] -= share
            }
        }

        return balances
    }

    /// Greedy "settle up" algorithm: repeatedly matches the member who owes
    /// the most with the member who is owed the most, settling the smaller
    /// of the two amounts in full. This is a well-known approach for
    /// minimizing the number of transactions needed to settle a group of
    /// balances that net out to zero (it is optimal in practice for the
    /// vast majority of real-world splitting scenarios, though the general
    /// minimum-transaction problem is NP-hard).
    ///
    /// - Parameter balances: net balance per member, as produced by
    ///   `netBalances(memberIDs:expenses:)`.
    /// - Returns: an ordered list of settlements. Members with a ~0 balance
    ///   are skipped entirely.
    static func settleUp(balances: [UUID: Double]) -> [Settlement] {
        // Round to cents to avoid floating point drift accumulating across
        // many expenses, then drop anyone who's already settled.
        var creditors: [(id: UUID, amount: Double)] = []
        var debtors: [(id: UUID, amount: Double)] = []

        for (id, rawAmount) in balances {
            let amount = (rawAmount * 100).rounded() / 100
            if amount > epsilon {
                creditors.append((id, amount))
            } else if amount < -epsilon {
                debtors.append((id, -amount)) // store as a positive "amount owed"
            }
        }

        // Sort descending so the biggest creditor/debtor pair settles first.
        // This greedy ordering is what keeps the transaction count minimal.
        creditors.sort { $0.amount > $1.amount }
        debtors.sort { $0.amount > $1.amount }

        var settlements: [Settlement] = []
        var creditorIndex = 0
        var debtorIndex = 0

        while creditorIndex < creditors.count && debtorIndex < debtors.count {
            var creditor = creditors[creditorIndex]
            var debtor = debtors[debtorIndex]

            let settledAmount = min(creditor.amount, debtor.amount)
            let rounded = (settledAmount * 100).rounded() / 100

            if rounded > epsilon {
                settlements.append(Settlement(fromID: debtor.id, toID: creditor.id, amount: rounded))
            }

            creditor.amount -= settledAmount
            debtor.amount -= settledAmount
            creditors[creditorIndex] = creditor
            debtors[debtorIndex] = debtor

            if creditor.amount <= epsilon {
                creditorIndex += 1
            }
            if debtor.amount <= epsilon {
                debtorIndex += 1
            }
        }

        return settlements
    }

    /// Convenience that goes straight from expenses to a minimized
    /// settlement list, for call sites that don't need the intermediate
    /// per-member balances.
    static func simplifiedSettlements(memberIDs: [UUID], expenses: [ExpenseInput]) -> [Settlement] {
        settleUp(balances: netBalances(memberIDs: memberIDs, expenses: expenses))
    }
}
