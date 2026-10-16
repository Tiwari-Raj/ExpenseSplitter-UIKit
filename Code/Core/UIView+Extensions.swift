//
//  UIView+Extensions.swift
//  ExpenseSplitter
//
//  Small, reusable helpers used throughout the UI layer.
//

import UIKit

extension UIView {

    /// Adds all given subviews in one call and disables autoresizing masks,
    /// since every screen in this app lays out with Auto Layout constraints.
    func addSubviews(_ views: UIView...) {
        views.forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
    }

    /// Pins the view to its superview's edges, optionally respecting the
    /// layout margins guide and with custom insets.
    @discardableResult
    func pinToSuperviewEdges(insets: UIEdgeInsets = .zero, useMargins: Bool = false) -> [NSLayoutConstraint] {
        guard let superview = superview else { return [] }
        translatesAutoresizingMaskIntoConstraints = false

        let guide: LayoutRegion = useMargins ? superview.layoutMarginsGuide : superview as LayoutRegion

        let constraints = [
            leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -insets.right),
            topAnchor.constraint(equalTo: guide.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -insets.bottom)
        ]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    /// Applies the app's standard card look (rounded corners + subtle shadow),
    /// using the shared Theme metrics so every card looks consistent.
    func applyCardStyle(backgroundColor: UIColor = Theme.Colors.cardBackground) {
        self.backgroundColor = backgroundColor
        layer.cornerRadius = Theme.Metrics.cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Theme.Metrics.shadowOpacity
        layer.shadowRadius = Theme.Metrics.shadowRadius
        layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    /// Rounds specific corners of a view to a given radius.
    func roundCorners(_ corners: CACornerMask, radius: CGFloat) {
        layer.cornerRadius = radius
        layer.maskedCorners = corners
    }

    /// Adds a thin bottom border, used as a lightweight separator under text fields.
    func addBottomBorder(color: UIColor = Theme.Colors.separator, height: CGFloat = 1) {
        let border = UIView()
        border.backgroundColor = color
        border.translatesAutoresizingMaskIntoConstraints = false
        addSubview(border)
        NSLayoutConstraint.activate([
            border.leadingAnchor.constraint(equalTo: leadingAnchor),
            border.trailingAnchor.constraint(equalTo: trailingAnchor),
            border.bottomAnchor.constraint(equalTo: bottomAnchor),
            border.heightAnchor.constraint(equalToConstant: height)
        ])
    }
}

/// A protocol both `UIView` and `UILayoutGuide` already conform to, used so
/// `pinToSuperviewEdges` can target either a view or its margins guide.
protocol LayoutRegion {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
}

extension UIView: LayoutRegion {}
extension UILayoutGuide: LayoutRegion {}

extension UIViewController {

    /// Presents a simple one-button alert, used for lightweight validation errors
    /// (e.g. "Please enter a valid amount").
    func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
