//
//  Theme.swift
//  ExpenseSplitter
//
//  Centralized design tokens for the whole app.
//
//  IMPORTANT: Every other file in this project must reference `Theme.x`
//  (colors, fonts, spacing, corner radii, etc.) instead of hardcoding
//  UIColor / UIFont / CGFloat literals. To re-theme the entire app,
//  edit only this file.
//

import UIKit

enum Theme {

    // MARK: - Colors

    enum Colors {
        /// Primary brand color — used for main actions, nav bar tint, selected states.
        static let primary = UIColor(named: "AccentColor") ?? UIColor.systemTeal

        /// Secondary accent, used for positive/credit amounts ("you are owed").
        static let positive = UIColor.systemGreen

        /// Used for negative/debit amounts ("you owe").
        static let negative = UIColor.systemRed

        /// Neutral accent for informational highlights (e.g. totals).
        static let accentSecondary = UIColor.systemOrange

        /// Main screen background.
        static let background = UIColor.systemGroupedBackground

        /// Card / cell background.
        static let cardBackground = UIColor.secondarySystemGroupedBackground

        /// Primary text color.
        static let textPrimary = UIColor.label

        /// Secondary / subdued text color.
        static let textSecondary = UIColor.secondaryLabel

        /// Placeholder text color for text fields.
        static let placeholder = UIColor.tertiaryLabel

        /// Divider / separator color.
        static let separator = UIColor.separator

        /// Color used for destructive actions (delete, remove).
        static let destructive = UIColor.systemRed

        /// Color used for disabled controls.
        static let disabled = UIColor.systemGray3
    }

    // MARK: - Fonts

    enum Fonts {
        /// Large title, e.g. screen headers.
        static let largeTitle = UIFont.systemFont(ofSize: 28, weight: .bold)

        /// Section / screen title.
        static let title = UIFont.systemFont(ofSize: 22, weight: .bold)

        /// Card / cell title (e.g. group name, expense description).
        static let headline = UIFont.systemFont(ofSize: 17, weight: .semibold)

        /// Standard body text.
        static let body = UIFont.systemFont(ofSize: 16, weight: .regular)

        /// Subdued supporting text (timestamps, member counts).
        static let subheadline = UIFont.systemFont(ofSize: 14, weight: .regular)

        /// Small captions, e.g. under balances.
        static let caption = UIFont.systemFont(ofSize: 12, weight: .medium)

        /// Monospaced font for currency amounts, so digits align.
        static let amount = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .semibold)

        /// Large monospaced font for totals.
        static let amountLarge = UIFont.monospacedDigitSystemFont(ofSize: 32, weight: .bold)

        /// Button label font.
        static let button = UIFont.systemFont(ofSize: 17, weight: .semibold)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxSmall: CGFloat = 2
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
    }

    // MARK: - Metrics

    enum Metrics {
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let buttonHeight: CGFloat = 50
        static let textFieldHeight: CGFloat = 44
        static let cellMinHeight: CGFloat = 64
        static let avatarSize: CGFloat = 36
        static let borderWidth: CGFloat = 1
        static let shadowOpacity: Float = 0.08
        static let shadowRadius: CGFloat = 6
    }
}
