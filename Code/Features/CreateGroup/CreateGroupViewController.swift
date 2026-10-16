//
//  CreateGroupViewController.swift
//  ExpenseSplitter
//
//  Screen 2: create a group — name + add members, then save.
//

import UIKit

final class CreateGroupViewController: UIViewController {

    /// Called after the group is successfully saved, so the presenting
    /// screen can refresh its list.
    var onGroupCreated: (() -> Void)?

    private let viewModel: CreateGroupViewModel

    private let groupNameField: UITextField = {
        let field = UITextField()
        field.placeholder = "Group name (e.g. Goa Trip)"
        field.font = Theme.Fonts.title
        field.textColor = Theme.Colors.textPrimary
        field.returnKeyType = .next
        field.autocapitalizationType = .words
        return field
    }()

    private let memberNameField: UITextField = {
        let field = UITextField()
        field.placeholder = "Member name"
        field.font = Theme.Fonts.body
        field.textColor = Theme.Colors.textPrimary
        field.returnKeyType = .done
        field.autocapitalizationType = .words
        field.borderStyle = .roundedRect
        return field
    }()

    private let addMemberButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Add"
        config.baseBackgroundColor = Theme.Colors.primary
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }()

    private let membersTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.isScrollEnabled = true
        return tableView
    }()

    init(viewModel: CreateGroupViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Group"
        view.backgroundColor = Theme.Colors.background

        setUpNavigationBar()
        setUpLayout()

        groupNameField.delegate = self
        memberNameField.delegate = self
        addMemberButton.addTarget(self, action: #selector(didTapAddMember), for: .touchUpInside)

        membersTableView.dataSource = self
        membersTableView.delegate = self
        membersTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MemberRow")
    }

    private func setUpNavigationBar() {
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
    }

    private func setUpLayout() {
        let addMemberRow = UIStackView(arrangedSubviews: [memberNameField, addMemberButton])
        addMemberRow.axis = .horizontal
        addMemberRow.spacing = Theme.Spacing.small
        addMemberRow.alignment = .center
        addMemberButton.widthAnchor.constraint(equalToConstant: 72).isActive = true

        let membersHeaderLabel: UILabel = {
            let label = UILabel()
            label.text = "Members"
            label.font = Theme.Fonts.subheadline
            label.textColor = Theme.Colors.textSecondary
            return label
        }()

        let stack = UIStackView(arrangedSubviews: [
            groupNameField,
            separatorView(),
            addMemberRow,
            membersHeaderLabel,
            membersTableView
        ])
        stack.axis = .vertical
        stack.spacing = Theme.Spacing.large

        view.addSubviews(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Theme.Spacing.large),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Theme.Spacing.large),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Theme.Spacing.large),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Theme.Spacing.large)
        ])
    }

    private func separatorView() -> UIView {
        let view = UIView()
        view.backgroundColor = Theme.Colors.separator
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return view
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    @objc private func didTapAddMember() {
        addMember()
    }

    private func addMember() {
        let result = viewModel.addMember(named: memberNameField.text ?? "")
        switch result {
        case .success:
            memberNameField.text = ""
            membersTableView.reloadData()
        case .failure(let error):
            presentAlert(title: "Can't add member", message: error.errorDescription ?? "")
        }
    }

    @objc private func didTapSave() {
        let result = viewModel.createGroup(named: groupNameField.text ?? "")
        switch result {
        case .success:
            onGroupCreated?()
            dismiss(animated: true)
        case .failure(let error):
            presentAlert(title: "Can't create group", message: error.errorDescription ?? "")
        }
    }
}

// MARK: - UITextFieldDelegate

extension CreateGroupViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === groupNameField {
            memberNameField.becomeFirstResponder()
        } else if textField === memberNameField {
            addMember()
        }
        return true
    }
}

// MARK: - UITableViewDataSource / Delegate

extension CreateGroupViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfMembers
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberRow", for: indexPath)
        cell.textLabel?.text = viewModel.memberName(at: indexPath.row)
        cell.textLabel?.font = Theme.Fonts.body
        cell.selectionStyle = .none
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
        viewModel.removeMember(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}
