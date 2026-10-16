//
//  GroupDetailViewController.swift
//  ExpenseSplitter
//
//  Screen 3: expenses in a group + running total + link to Balances.
//

import UIKit

final class GroupDetailViewController: UIViewController {

    private let viewModel: GroupDetailViewModel

    private let totalCard: UIView = {
        let view = UIView()
        view.applyCardStyle()
        return view
    }()

    private let totalTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Total spent"
        label.font = Theme.Fonts.subheadline
        label.textColor = Theme.Colors.textSecondary
        return label
    }()

    private let totalAmountLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.amountLarge
        label.textColor = Theme.Colors.textPrimary
        return label
    }()

    private let balancesButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "View Balances"
        config.image = UIImage(systemName: "arrow.left.arrow.right")
        config.imagePadding = Theme.Spacing.small
        config.baseBackgroundColor = Theme.Colors.primary
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No expenses yet.\nTap + to add one."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = Theme.Fonts.body
        label.textColor = Theme.Colors.textSecondary
        return label
    }()

    init(viewModel: GroupDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.groupName
        view.backgroundColor = Theme.Colors.background
        viewModel.delegate = self

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAddExpense)
        )

        setUpHeader()
        setUpTableView()
        setUpEmptyState()

        balancesButton.addTarget(self, action: #selector(didTapBalances), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadExpenses()
    }

    private func setUpHeader() {
        let totalStack = UIStackView(arrangedSubviews: [totalTitleLabel, totalAmountLabel])
        totalStack.axis = .vertical
        totalStack.spacing = Theme.Spacing.xSmall

        totalCard.addSubviews(totalStack)
        NSLayoutConstraint.activate([
            totalStack.leadingAnchor.constraint(equalTo: totalCard.leadingAnchor, constant: Theme.Spacing.large),
            totalStack.trailingAnchor.constraint(lessThanOrEqualTo: totalCard.trailingAnchor, constant: -Theme.Spacing.large),
            totalStack.topAnchor.constraint(equalTo: totalCard.topAnchor, constant: Theme.Spacing.large),
            totalStack.bottomAnchor.constraint(equalTo: totalCard.bottomAnchor, constant: -Theme.Spacing.large)
        ])

        view.addSubviews(totalCard, balancesButton)
        NSLayoutConstraint.activate([
            totalCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Theme.Spacing.large),
            totalCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Theme.Spacing.large),
            totalCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Theme.Spacing.large),

            balancesButton.topAnchor.constraint(equalTo: totalCard.bottomAnchor, constant: Theme.Spacing.medium),
            balancesButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Theme.Spacing.large),
            balancesButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Theme.Spacing.large),
            balancesButton.heightAnchor.constraint(equalToConstant: Theme.Metrics.buttonHeight)
        ])
    }

    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ExpenseCell.self, forCellReuseIdentifier: ExpenseCell.reuseIdentifier)
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Theme.Metrics.cellMinHeight

        view.addSubviews(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: balancesButton.bottomAnchor, constant: Theme.Spacing.medium),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setUpEmptyState() {
        view.addSubviews(emptyStateLabel)
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: -Theme.Spacing.xLarge),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: Theme.Spacing.xLarge),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Theme.Spacing.xLarge)
        ])
    }

    private func refreshHeader() {
        totalAmountLabel.text = CurrencyFormatter.string(from: viewModel.totalSpent)
    }

    @objc private func didTapAddExpense() {
        let addExpenseViewModel = AddExpenseViewModel(group: viewModel.group, context: CoreDataStack.shared.viewContext)
        let addExpenseViewController = AddExpenseViewController(viewModel: addExpenseViewModel)
        addExpenseViewController.onExpenseSaved = { [weak self] in
            self?.viewModel.loadExpenses()
        }
        let navigationController = UINavigationController(rootViewController: addExpenseViewController)
        present(navigationController, animated: true)
    }

    @objc private func didTapBalances() {
        let balancesViewModel = BalancesViewModel(group: viewModel.group, context: CoreDataStack.shared.viewContext)
        let balancesViewController = BalancesViewController(viewModel: balancesViewModel)
        navigationController?.pushViewController(balancesViewController, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension GroupDetailViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfExpenses
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ExpenseCell.reuseIdentifier,
            for: indexPath
        ) as? ExpenseCell else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.expense(at: indexPath.row))
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        guard editingStyle == .delete else { return }
        viewModel.deleteExpense(at: indexPath.row)
    }
}

// MARK: - UITableViewDelegate

extension GroupDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - GroupDetailViewModelDelegate

extension GroupDetailViewController: GroupDetailViewModelDelegate {

    func groupDetailDidUpdate() {
        tableView.reloadData()
        refreshHeader()
        emptyStateLabel.isHidden = viewModel.numberOfExpenses > 0
    }
}
