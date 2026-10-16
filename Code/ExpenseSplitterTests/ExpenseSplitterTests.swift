//
//  ExpenseSplitterTests.swift
//  ExpenseSplitterTests
//
//

import XCTest
@testable import ExpenseSplitter

final class ExpenseSplitterTests: XCTestCase {

    // Fixed UUIDs so failure messages are readable and assertions are stable.
    private let alice = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let bob = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    private let carol = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    private let dave = UUID(uuidString: "00000000-0000-0000-0000-000000000004")!

    // MARK: - Equal split balance math

    func test_singleExpense_splitEqually_twoPeople() {
        // Alice pays $100, split equally between Alice and Bob.
        // Alice should be owed $50, Bob should owe $50.
        let expense = ExpenseInput(amount: 100, paidByID: alice, splitAmongIDs: [alice, bob])
        let balances = BalanceCalculator.netBalances(memberIDs: [alice, bob], expenses: [expense])

        XCTAssertEqual(balances[alice]!, 50, accuracy: 0.001)
        XCTAssertEqual(balances[bob]!, -50, accuracy: 0.001)
    }

    func test_singleExpense_splitEqually_threePeople() {
        // Carol pays $90 split three ways: she's owed $60, the other two owe $30 each.
        let expense = ExpenseInput(amount: 90, paidByID: carol, splitAmongIDs: [alice, bob, carol])
        let balances = BalanceCalculator.netBalances(memberIDs: [alice, bob, carol], expenses: [expense])

        XCTAssertEqual(balances[carol]!, 60, accuracy: 0.001)
        XCTAssertEqual(balances[alice]!, -30, accuracy: 0.001)
        XCTAssertEqual(balances[bob]!, -30, accuracy: 0.001)
    }

    func test_multipleExpenses_accumulateCorrectly() {
        // Alice pays $60 split with Bob (Bob owes $30).
        // Bob pays $40 split with Alice (Alice owes $20).
        // Net: Alice is owed $30 - $20 = $10; Bob owes $10.
        let expense1 = ExpenseInput(amount: 60, paidByID: alice, splitAmongIDs: [alice, bob])
        let expense2 = ExpenseInput(amount: 40, paidByID: bob, splitAmongIDs: [alice, bob])
        let balances = BalanceCalculator.netBalances(memberIDs: [alice, bob], expenses: [expense1, expense2])

        XCTAssertEqual(balances[alice]!, 10, accuracy: 0.001)
        XCTAssertEqual(balances[bob]!, -10, accuracy: 0.001)
    }

    func test_memberNotInSplit_isUnaffectedByThatExpense() {
        // Dave is in the group but not part of this particular expense's split.
        let expense = ExpenseInput(amount: 100, paidByID: alice, splitAmongIDs: [alice, bob])
        let balances = BalanceCalculator.netBalances(memberIDs: [alice, bob, dave], expenses: [expense])

        XCTAssertEqual(balances[dave]!, 0, accuracy: 0.001)
    }

    func test_balancesAlwaysSumToZero() {
        let expenses = [
            ExpenseInput(amount: 100, paidByID: alice, splitAmongIDs: [alice, bob, carol]),
            ExpenseInput(amount: 45.50, paidByID: bob, splitAmongIDs: [alice, bob, carol, dave]),
            ExpenseInput(amount: 10, paidByID: carol, splitAmongIDs: [carol, dave])
        ]
        let balances = BalanceCalculator.netBalances(memberIDs: [alice, bob, carol, dave], expenses: expenses)
        let total = balances.values.reduce(0, +)

        XCTAssertEqual(total, 0, accuracy: 0.01)
    }

    func test_emptyExpenses_allBalancesAreZero() {
        let balances = BalanceCalculator.netBalances(memberIDs: [alice, bob, carol], expenses: [])

        XCTAssertEqual(balances[alice]!, 0, accuracy: 0.001)
        XCTAssertEqual(balances[bob]!, 0, accuracy: 0.001)
        XCTAssertEqual(balances[carol]!, 0, accuracy: 0.001)
    }

    // MARK: - Settlement simplification

    func test_settleUp_twoPeople_oneSettlement() {
        // Alice is owed $50, Bob owes $50 -> exactly 1 transaction.
        let balances: [UUID: Double] = [alice: 50, bob: -50]
        let settlements = BalanceCalculator.settleUp(balances: balances)

        XCTAssertEqual(settlements.count, 1)
        XCTAssertEqual(settlements[0].fromID, bob)
        XCTAssertEqual(settlements[0].toID, alice)
        XCTAssertEqual(settlements[0].amount, 50, accuracy: 0.001)
    }

    func test_settleUp_alreadySettled_noTransactions() {
        let balances: [UUID: Double] = [alice: 0, bob: 0, carol: 0]
        let settlements = BalanceCalculator.settleUp(balances: balances)

        XCTAssertTrue(settlements.isEmpty)
    }

    func test_settleUp_minimizesTransactionCount() {
        // Classic "3 debtors, 1 creditor" case: naive pairwise settlement
        // between every pair who transacted together could take many more
        // transactions; the greedy algorithm should settle this group of 4
        // people in at most 3 transactions (n - 1 for n participants with
        // non-zero balance), not the 6 pairwise relationships that could
        // exist if everyone paid for everyone.
        let balances: [UUID: Double] = [
            alice: 90,   // owed 90 overall
            bob: -30,    // owes 30
            carol: -30,  // owes 30
            dave: -30    // owes 30
        ]
        let settlements = BalanceCalculator.settleUp(balances: balances)

        XCTAssertEqual(settlements.count, 3)
        // Every settlement should flow into Alice, and amounts should sum to 90.
        XCTAssertTrue(settlements.allSatisfy { $0.toID == alice })
        let total = settlements.reduce(0) { $0 + $1.amount }
        XCTAssertEqual(total, 90, accuracy: 0.01)
    }

    func test_settleUp_fourPeople_complexCase_minimizesToThreeOrFewer() {
        // A more complex, realistic net-balance scenario across 4 people.
        // However these arose, the greedy algorithm should need at most
        // (participants with non-zero balance - 1) = 3 transactions.
        let balances: [UUID: Double] = [
            alice: 40,
            bob: 25,
            carol: -35,
            dave: -30
        ]
        let settlements = BalanceCalculator.settleUp(balances: balances)

        XCTAssertLessThanOrEqual(settlements.count, 3)

        // Verify the settlements actually zero out each person's balance.
        var reconstructed: [UUID: Double] = [alice: 0, bob: 0, carol: 0, dave: 0]
        for settlement in settlements {
            reconstructed[settlement.fromID, default: 0] -= settlement.amount
            reconstructed[settlement.toID, default: 0] += settlement.amount
        }
        for (id, originalBalance) in balances {
            XCTAssertEqual(reconstructed[id]!, originalBalance, accuracy: 0.01, "Mismatch for \(id)")
        }
    }

    func test_settleUp_ignoresNegligibleBalances() {
        // A balance of a fraction of a cent (floating point noise) should
        // not produce a spurious settlement.
        let balances: [UUID: Double] = [alice: 0.001, bob: -0.001]
        let settlements = BalanceCalculator.settleUp(balances: balances)

        XCTAssertTrue(settlements.isEmpty)
    }

    // MARK: - End-to-end: expenses -> simplified settlements

    func test_simplifiedSettlements_fromExpenses_endToEnd() {
        // A trip with 3 friends:
        // Alice pays $120 dinner, split 3 ways (Alice, Bob, Carol).
        // Bob pays $60 taxi, split 3 ways (Alice, Bob, Carol).
        // Expected net: Alice spent 120, owes 60 -> +60
        //               Bob spent 60, owes 60 -> 0
        //               Carol spent 0, owes 60 -> -60
        // So the simplified settlement should be exactly: Carol pays Alice $60.
        let expenses = [
            ExpenseInput(amount: 120, paidByID: alice, splitAmongIDs: [alice, bob, carol]),
            ExpenseInput(amount: 60, paidByID: bob, splitAmongIDs: [alice, bob, carol])
        ]
        let settlements = BalanceCalculator.simplifiedSettlements(
            memberIDs: [alice, bob, carol],
            expenses: expenses
        )

        XCTAssertEqual(settlements.count, 1)
        XCTAssertEqual(settlements[0].fromID, carol)
        XCTAssertEqual(settlements[0].toID, alice)
        XCTAssertEqual(settlements[0].amount, 60, accuracy: 0.01)
    }

}
