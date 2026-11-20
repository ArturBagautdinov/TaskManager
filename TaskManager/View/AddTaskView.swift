import UIKit

final class AddTaskView: UIView {
    private let fieldCornerRadius: CGFloat = 16
    private let titleField = UITextField()
    private let detailsView = UITextView()
    private let priorities = TaskPriority.allCases
    private lazy var priorityControl = UISegmentedControl(items: priorities.map(\.displayTitle))

    var taskTitle: String { titleField.text ?? "" }
    var details: String { detailsView.text ?? "" }

    var priority: TaskPriority {
        let index = priorityControl.selectedSegmentIndex
        return priorities.indices.contains(index) ? priorities[index] : .defaultPriority
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureForm()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    private func configureForm() {
        backgroundColor = .systemGroupedBackground

        titleField.backgroundColor = .secondarySystemGroupedBackground
        titleField.layer.cornerRadius = fieldCornerRadius
        titleField.layer.borderWidth = 0.5
        updateTitleFieldBorderColor()
        registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) { (view: AddTaskView, _) in
            view.updateTitleFieldBorderColor()
        }

        let textInset = CGRect(x: 0, y: 0, width: 8, height: 1)
        titleField.leftView = UIView(frame: textInset)
        titleField.leftViewMode = .always
        titleField.rightView = UIView(frame: textInset)
        titleField.rightViewMode = .always
        titleField.font = .preferredFont(forTextStyle: .body)
        titleField.adjustsFontForContentSizeCategory = true
        titleField.accessibilityLabel = "Название"

        detailsView.font = .preferredFont(forTextStyle: .body)
        detailsView.adjustsFontForContentSizeCategory = true
        detailsView.backgroundColor = .secondarySystemGroupedBackground
        detailsView.layer.cornerRadius = fieldCornerRadius
        detailsView.accessibilityLabel = "Описание"

        priorityControl.selectedSegmentIndex = priorities.firstIndex(of: .defaultPriority)
            ?? UISegmentedControl.noSegment
        priorityControl.accessibilityLabel = "Приоритет"

        let stack = UIStackView(arrangedSubviews: [
            makeFieldGroup(title: "Название", control: titleField),
            makeFieldGroup(title: "Описание", control: detailsView),
            makeFieldGroup(title: "Приоритет", control: priorityControl)
        ])
        stack.axis = .vertical
        stack.spacing = 20

        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        scrollView.addSubview(stack)

        let safeArea = safeAreaLayoutGuide
        let content = scrollView.contentLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor),

            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),

            titleField.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            detailsView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }

    private func updateTitleFieldBorderColor() {
        titleField.layer.borderColor = UIColor.separator.resolvedColor(with: traitCollection).cgColor
    }

    private func makeFieldGroup(title: String, control: UIView) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.isAccessibilityElement = false

        let group = UIStackView(arrangedSubviews: [label, control])
        group.axis = .vertical
        group.spacing = 8
        return group
    }
}
