//
//  AddExpenseViewController.swift
//  ExpenseSplitter
//
//  Screen 4: description, amount, paid-by (single select) and
//  split-among (checkboxes).
//

import UIKit

final class AddExpenseViewController: UIViewController {

    /// Called after the expense is successfully saved.
    var onExpenseSaved: (() -> Void)?

    private let viewModel: AddExpenseViewModel

    private let descriptionField: UITextField = {
        let field = UITextField()
        field.placeholder = "Description (e.g. Dinner)"
        field.font = Theme.Fonts.headline
        field.textColor = Theme.Colors.textPrimary
        field.returnKeyType = .next
        field.autocapitalizationType = .sentences
        return field
    }()

    private let amountField: UITextField = {
        let field = UITextField()
        field.placeholder = "0.00"
        field.font = Theme.Fonts.amountLarge
        field.textColor = Theme.Colors.textPrimary
        field.keyboardType = .decimalPad
        field.textAlignment = .right
        return field
    }()

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private enum Section: Int, CaseIterable {
        case paidBy
        case splitAmong

        var title: String {
            switch self {
            case .paidBy: return "Paid by"
            case .splitAmong: return "Split among"
            }
        }
    }

    init(viewModel: AddExpenseViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Expense"
        view.backgroundColor = Theme.Colors.background

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(didTapCancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(didTapSave)
        )

        descriptionField.delegate = self

        setUpTableView()
    }

    private func setUpTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MemberCheckboxCell.self, forCellReuseIdentifier: MemberCheckboxCell.reuseIdentifier)
        tableView.tableHeaderView = makeHeaderView()

        view.addSubviews(tableView)
        tableView.pinToSuperviewEdges()
    }

    private func makeHeaderView() -> UIView {
        let card = UIView()
        card.applyCardStyle()

        let amountRow = UIStackView(arrangedSubviews: [currencySymbolLabel(), amountField])
        amountRow.axis = .horizontal
        amountRow.spacing = Theme.Spacing.xSmall

        let separator = UIView()
        separator.backgroundColor = Theme.Colors.separator

        let stack = UIStackView(arrangedSubviews: [descriptionField, separator, amountRow])
        stack.axis = .vertical
        stack.spacing = Theme.Spacing.medium

        card.addSubviews(stack)
        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 1),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Theme.Spacing.large),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -Theme.Spacing.large),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: Theme.Spacing.large),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -Theme.Spacing.large)
        ])

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 150))
        container.addSubviews(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Theme.Spacing.large),
            card.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Theme.Spacing.large),
            card.topAnchor.constraint(equalTo: container.topAnchor, constant: Theme.Spacing.large),
            card.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Theme.Spacing.small)
        ])
        return container
    }

    private func currencySymbolLabel() -> UILabel {
        let label = UILabel()
        label.text = Locale.current.currencySymbol ?? "$"
        label.font = Theme.Fonts.amountLarge
        label.textColor = Theme.Colors.textSecondary
        return label
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    @objc private func didTapSave() {
        let result = viewModel.saveExpense(
            description: descriptionField.text ?? "",
            amountText: amountField.text ?? ""
        )
        switch result {
        case .success:
            onExpenseSaved?()
            dismiss(animated: true)
        case .failure(let error):
            presentAlert(title: "Can't save expense", message: error.errorDescription ?? "")
        }
    }
}

// MARK: - UITextFieldDelegate

extension AddExpenseViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === descriptionField {
            amountField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - UITableViewDataSource

extension AddExpenseViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfMembers
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: MemberCheckboxCell.reuseIdentifier,
            for: indexPath
        ) as? MemberCheckboxCell else {
            return UITableViewCell()
        }

        let name = viewModel.memberName(at: indexPath.row)
        switch Section(rawValue: indexPath.section) {
        case .paidBy:
            cell.configure(name: name, isSelected: indexPath.row == viewModel.paidByIndex, style: .radio)
        case .splitAmong:
            cell.configure(name: name, isSelected: viewModel.isSplitSelected(at: indexPath.row), style: .checkbox)
        case .none:
            break
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AddExpenseViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch Section(rawValue: indexPath.section) {
        case .paidBy:
            viewModel.selectPaidBy(index: indexPath.row)
            tableView.reloadSections(IndexSet(integer: Section.paidBy.rawValue), with: .none)
        case .splitAmong:
            viewModel.toggleSplit(at: indexPath.row)
            tableView.reloadRows(at: [indexPath], with: .none)
        case .none:
            break
        }
    }
}
