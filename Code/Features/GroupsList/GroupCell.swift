//
//  GroupCell.swift
//  ExpenseSplitter
//

import UIKit

final class GroupCell: UITableViewCell {

    static let reuseIdentifier = "GroupCell"

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.headline
        label.textColor = Theme.Colors.textPrimary
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.subheadline
        label.textColor = Theme.Colors.textSecondary
        return label
    }()

    private let totalLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.amount
        label.textColor = Theme.Colors.primary
        label.textAlignment = .right
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpLayout() {
        accessoryType = .disclosureIndicator

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = Theme.Spacing.xxSmall

        contentView.addSubviews(textStack, totalLabel)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Theme.Spacing.large),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Theme.Spacing.medium),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Theme.Spacing.medium),

            totalLabel.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: Theme.Spacing.small),
            totalLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Theme.Spacing.small),
            totalLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with summary: GroupSummary) {
        nameLabel.text = summary.name
        let memberWord = summary.memberCount == 1 ? "member" : "members"
        subtitleLabel.text = "\(summary.memberCount) \(memberWord)"
        totalLabel.text = CurrencyFormatter.string(from: summary.totalSpent)
    }
}
