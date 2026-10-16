//
//  GroupsListViewController.swift
//  ExpenseSplitter
//
//  Screen 1: list of groups, swipe to delete, "+" to create a new group.
//

import UIKit

final class GroupsListViewController: UIViewController {

    private let viewModel: GroupsListViewModel

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No groups yet.\nTap + to create your first group."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = Theme.Fonts.body
        label.textColor = Theme.Colors.textSecondary
        return label
    }()

    init(viewModel: GroupsListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Groups"
        view.backgroundColor = Theme.Colors.background
        viewModel.delegate = self

        setUpNavigationBar()
        setUpTableView()
        setUpEmptyState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadGroups()
    }

    private func setUpNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(didTapAddGroup)
        )
    }

    private func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(GroupCell.self, forCellReuseIdentifier: GroupCell.reuseIdentifier)
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Theme.Metrics.cellMinHeight

        view.addSubviews(tableView)
        tableView.pinToSuperviewEdges()
    }

    private func setUpEmptyState() {
        view.addSubviews(emptyStateLabel)
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: Theme.Spacing.xLarge),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Theme.Spacing.xLarge)
        ])
    }

    @objc private func didTapAddGroup() {
        let createViewModel = CreateGroupViewModel(context: CoreDataStack.shared.viewContext)
        let createViewController = CreateGroupViewController(viewModel: createViewModel)
        createViewController.onGroupCreated = { [weak self] in
            self?.viewModel.loadGroups()
        }
        let navigationController = UINavigationController(rootViewController: createViewController)
        present(navigationController, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension GroupsListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfGroups
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: GroupCell.reuseIdentifier,
            for: indexPath
        ) as? GroupCell else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.group(at: indexPath.row))
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
        viewModel.deleteGroup(at: indexPath.row)
    }
}

// MARK: - UITableViewDelegate

extension GroupsListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let group = viewModel.managedGroup(at: indexPath.row) else { return }

        let detailViewModel = GroupDetailViewModel(group: group, context: CoreDataStack.shared.viewContext)
        let detailViewController = GroupDetailViewController(viewModel: detailViewModel)
        navigationController?.pushViewController(detailViewController, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.viewModel.deleteGroup(at: indexPath.row)
            completion(true)
        }
        deleteAction.backgroundColor = Theme.Colors.destructive
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - GroupsListViewModelDelegate

extension GroupsListViewController: GroupsListViewModelDelegate {

    func groupsListDidUpdate() {
        tableView.reloadData()
        emptyStateLabel.isHidden = viewModel.numberOfGroups > 0
    }
}
