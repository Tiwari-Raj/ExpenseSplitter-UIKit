//
//  BalancesViewController.swift
//  ExpenseSplitter
//
//  Screen 5: per-member net balances + a simplified "who owes whom"
//  settlement list.
//

import UIKit

final class BalancesViewController: UIViewController {

    private let viewModel: BalancesViewModel

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private enum Section: Int, CaseIterable {
        case balances
        case settlements

        var title: String {
            switch self {
            case .balances: return "Net Balances"
            case .settlements: return "Settle Up"
            }
        }
    }

    init(viewModel: BalancesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Balances"
        view.backgroundColor = Theme.Colors.background

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SettlementCell.self, forCellReuseIdentifier: SettlementCell.reuseIdentifier)

        view.addSubviews(tableView)
        tableView.pinToSuperviewEdges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.calculateBalances()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension BalancesViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .balances:
            return viewModel.numberOfMemberBalances
        case .settlements:
            return max(viewModel.numberOfSettlements, 1)
        case .none:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(rawValue: section) == .settlements else { return nil }
        return "This is the minimum number of payments needed to settle every balance in the group."
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .balances:
            let cell = dequeueValueCell(for: tableView)
            let balance = viewModel.memberBalance(at: indexPath.row)
            cell.selectionStyle = .none
            cell.textLabel?.text = balance.name
            cell.textLabel?.font = Theme.Fonts.body
            cell.detailTextLabel?.text = balance.amountText
            cell.detailTextLabel?.font = Theme.Fonts.amount
            if balance.isSettled {
                cell.detailTextLabel?.textColor = Theme.Colors.textSecondary
            } else {
                cell.detailTextLabel?.textColor = balance.isPositive ? Theme.Colors.positive : Theme.Colors.negative
            }
            return cell

        case .settlements:
            if viewModel.numberOfSettlements == 0 {
                let cell = dequeueValueCell(for: tableView)
                cell.selectionStyle = .none
                cell.textLabel?.text = "Everyone is settled up! 🎉"
                cell.textLabel?.font = Theme.Fonts.body
                cell.textLabel?.textColor = Theme.Colors.textSecondary
                cell.detailTextLabel?.text = nil
                return cell
            }
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SettlementCell.reuseIdentifier,
                for: indexPath
            ) as? SettlementCell else {
                return UITableViewCell()
            }
            cell.configure(with: viewModel.settlement(at: indexPath.row))
            return cell

        case .none:
            return UITableViewCell()
        }
    }

    /// `.value1` style shows a left-aligned title and a right-aligned detail
    /// label, which is what the balances rows need. UITableViewCell doesn't
    /// support registering a class with a specific style, so this creates
    /// one manually instead of using `dequeueReusableCell(withIdentifier:)`.
    private func dequeueValueCell(for tableView: UITableView) -> UITableViewCell {
        UITableViewCell(style: .value1, reuseIdentifier: "BalanceRow")
    }
}

// MARK: - UITableViewDelegate

extension BalancesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
