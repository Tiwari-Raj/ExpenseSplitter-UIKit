//
//  SettlementCell.swift
//  ExpenseSplitter
//

import UIKit

final class SettlementCell: UITableViewCell {

    static let reuseIdentifier = "SettlementCell"

    private let fromLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.headline
        label.textColor = Theme.Colors.negative
        return label
    }()

    private let arrowImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "arrow.right"))
        imageView.tintColor = Theme.Colors.textSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let toLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.headline
        label.textColor = Theme.Colors.positive
        return label
    }()

    private let amountLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Fonts.amount
        label.textColor = Theme.Colors.textPrimary
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
        selectionStyle = .none

        let namesStack = UIStackView(arrangedSubviews: [fromLabel, arrowImageView, toLabel])
        namesStack.axis = .horizontal
        namesStack.spacing = Theme.Spacing.small
        namesStack.alignment = .center
        arrowImageView.widthAnchor.constraint(equalToConstant: 16).isActive = true

        contentView.addSubviews(namesStack, amountLabel)

        NSLayoutConstraint.activate([
            namesStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Theme.Spacing.large),
            namesStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Theme.Spacing.medium),
            namesStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Theme.Spacing.medium),

            amountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: namesStack.trailingAnchor, constant: Theme.Spacing.small),
            amountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Theme.Spacing.large),
            amountLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with settlement: SettlementDisplay) {
        fromLabel.text = settlement.fromName
        toLabel.text = settlement.toName
        amountLabel.text = settlement.amountText
    }
}
