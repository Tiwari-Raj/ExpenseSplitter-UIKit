//
//  MemberCheckboxCell.swift
//  ExpenseSplitter
//
//  Reused for both the "paid by" (radio-style, single selection) and
//  "split among" (checkbox-style, multi selection) rows in Add Expense.
//

import UIKit

final class MemberCheckboxCell: UITableViewCell {

    static let reuseIdentifier = "MemberCheckboxCell"

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.body
        label.textColor = Theme.Colors.textPrimary
        return label
    }()

    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = Theme.Colors.primary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpLayout() {
        selectionStyle = .none
        contentView.addSubviews(nameLabel, checkmarkImageView)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Theme.Spacing.large),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Theme.Spacing.medium),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Theme.Spacing.medium),

            checkmarkImageView.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: Theme.Spacing.small),
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Theme.Spacing.large),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: Theme.Spacing.xLarge),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: Theme.Spacing.xLarge)
        ])
    }

    /// `style` controls whether the selected icon looks like a radio button
    /// (single "paid by" selection) or a checkbox (multi "split among" selection).
    enum SelectionStyle {
        case radio
        case checkbox
    }

    func configure(name: String, isSelected: Bool, style: SelectionStyle) {
        nameLabel.text = name

        let selectedSymbol = style == .radio ? "largecircle.fill.circle" : "checkmark.square.fill"
        let unselectedSymbol = style == .radio ? "circle" : "square"

        checkmarkImageView.image = UIImage(systemName: isSelected ? selectedSymbol : unselectedSymbol)
        checkmarkImageView.tintColor = isSelected ? Theme.Colors.primary : Theme.Colors.disabled
    }
}
