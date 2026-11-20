import UIKit

final class TaskCell: UITableViewCell {
    static let reuseIdentifier = "TaskCell"

    private let titleLabel = UILabel()
    private let detailsLabel = UILabel()
    private let creationDateLabel = UILabel()
    private let priorityBadge = BadgeView()
    private let statusBadge = BadgeView()
    private let badges = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let labels = [titleLabel, detailsLabel, creationDateLabel]
        for label in labels {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
        }

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        detailsLabel.font = .preferredFont(forTextStyle: .subheadline)
        detailsLabel.textColor = .secondaryLabel
        creationDateLabel.font = .preferredFont(forTextStyle: .footnote)
        creationDateLabel.textColor = .secondaryLabel

        let calendarIcon = UIImageView(image: UIImage(systemName: "calendar"))
        calendarIcon.preferredSymbolConfiguration = .init(textStyle: .footnote, scale: .small)
        calendarIcon.tintColor = .secondaryLabel
        calendarIcon.setContentHuggingPriority(.required, for: .horizontal)
        calendarIcon.setContentCompressionResistancePriority(.required, for: .horizontal)

        let dateRow = UIStackView(arrangedSubviews: [calendarIcon, creationDateLabel])
        dateRow.alignment = .center
        dateRow.spacing = 5

        badges.addArrangedSubview(priorityBadge)
        badges.addArrangedSubview(statusBadge)
        badges.alignment = .leading
        badges.spacing = 6
        updateBadgeLayout()
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (cell: TaskCell, _) in
            cell.updateBadgeLayout()
        }

        let badgeRow = UIView()
        badges.translatesAutoresizingMaskIntoConstraints = false
        badgeRow.addSubview(badges)

        let stack = UIStackView(arrangedSubviews: [titleLabel, detailsLabel, dateRow, badgeRow])
        stack.axis = .vertical
        stack.spacing = 6
        stack.setCustomSpacing(8, after: dateRow)
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        let margins = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: margins.topAnchor),
            stack.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: margins.bottomAnchor),

            badges.topAnchor.constraint(equalTo: badgeRow.topAnchor),
            badges.leadingAnchor.constraint(equalTo: badgeRow.leadingAnchor),
            badges.trailingAnchor.constraint(lessThanOrEqualTo: badgeRow.trailingAnchor),
            badges.bottomAnchor.constraint(equalTo: badgeRow.bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    func configure(with row: TaskViewModel.Row) {
        titleLabel.text = row.title
        detailsLabel.text = row.details
        detailsLabel.isHidden = row.details.isEmpty
        creationDateLabel.text = row.creationDateText
        let priorityColor: UIColor
        switch row.priority {
        case .low: priorityColor = .systemBlue
        case .medium: priorityColor = .systemOrange
        case .high: priorityColor = .systemRed
        }
        priorityBadge.configure(
            text: row.priorityText,
            symbol: "flag.fill",
            tint: priorityColor,
            fill: priorityColor.withAlphaComponent(0.12)
        )
        statusBadge.configure(
            text: row.statusText,
            symbol: row.isCompleted ? "checkmark.circle.fill" : "circle",
            tint: row.isCompleted ? .systemGreen : .secondaryLabel,
            fill: row.isCompleted ? UIColor.systemGreen.withAlphaComponent(0.12) : .tertiarySystemFill
        )
    }

    private func updateBadgeLayout() {
        badges.axis = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
    }

    private final class BadgeView: UIView {
        private let icon = UIImageView()
        private let label = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)
            layer.cornerRadius = 8

            label.font = .preferredFont(forTextStyle: .caption1)
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            icon.preferredSymbolConfiguration = .init(textStyle: .caption1, scale: .small)
            icon.setContentHuggingPriority(.required, for: .horizontal)
            icon.setContentCompressionResistancePriority(.required, for: .horizontal)

            let stack = UIStackView(arrangedSubviews: [icon, label])
            stack.alignment = .center
            stack.spacing = 4
            stack.translatesAutoresizingMaskIntoConstraints = false
            addSubview(stack)
            directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 7, bottom: 4, trailing: 7)

            let margins = layoutMarginsGuide
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: margins.topAnchor),
                stack.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
                stack.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
            ])
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            return nil
        }

        func configure(text: String, symbol: String, tint: UIColor, fill: UIColor) {
            label.text = text
            icon.image = UIImage(systemName: symbol)
            icon.tintColor = tint
            backgroundColor = fill
        }
    }
}
