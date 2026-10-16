//
//  ExpenseCell.swift
//  ExpenseSplitter
//

import UIKit

final class ExpenseCell: UITableViewCell {

    static let reuseIdentifier = "ExpenseCell"

    private let descriptionLabel: UILabel = {
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

    private let amountLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.amount
        label.textColor = Theme.Colors.accentSecondary
        label.textAlignment = .right
        return label
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpLayout() {
        let textStack = UIStackView(arrangedSubviews: [descriptionLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = Theme.Spacing.xxSmall

        contentView.addSubviews(textStack, amountLabel)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Theme.Spacing.large),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Theme.Spacing.medium),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Theme.Spacing.medium),

            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: Theme.Spacing.small),
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Theme.Spacing.large),
            amountLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with summary: ExpenseSummary) {
        descriptionLabel.text = summary.description
        let dateString = Self.dateFormatter.string(from: summary.date)
        subtitleLabel.text = "Paid by \(summary.paidByName) · \(dateString)"
        amountLabel.text = CurrencyFormatter.string(from: summary.amount)
    }
}
