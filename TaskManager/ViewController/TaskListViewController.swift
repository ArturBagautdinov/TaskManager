import UIKit

final class TaskListViewController: UIViewController {
    private let viewModel: TaskViewModel
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let filterButton = UIButton(type: .system)
    private let sortButton = UIButton(type: .system)
    private let listControls = UIStackView()
    private let emptyLabel = UILabel()

    var onAddTask: (() -> Void)?

    init(viewModel: TaskViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        viewModel.onError = { [weak self] message in
            self?.showError(message)
        }
        viewModel.refresh()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateControlsLayout()
    }

    private func configureView() {
        title = "Задачи"
        view.backgroundColor = .systemGroupedBackground

        let addButton = UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak self] _ in
            self?.onAddTask?()
        })
        addButton.accessibilityLabel = "Добавить задачу"
        navigationItem.rightBarButtonItem = addButton

        var configuration = UIButton.Configuration.filled()
        configuration.baseForegroundColor = .label
        configuration.baseBackgroundColor = .secondarySystemGroupedBackground
        configuration.background.strokeColor = .separator
        configuration.background.strokeWidth = 0.5
        configuration.cornerStyle = .capsule
        configuration.image = UIImage(systemName: "chevron.down")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 8
        configuration.titleLineBreakMode = .byTruncatingTail

        for button in [filterButton, sortButton] {
            button.configuration = configuration
            button.showsMenuAsPrimaryAction = true
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            listControls.addArrangedSubview(button)
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        }
        filterButton.accessibilityIdentifier = "taskFilter"
        filterButton.accessibilityLabel = "Фильтр задач"
        sortButton.accessibilityIdentifier = "taskSortOrder"
        sortButton.accessibilityLabel = "Порядок сортировки"
        listControls.alignment = .center
        listControls.spacing = 8

        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = .preferredFont(forTextStyle: .body)
        emptyLabel.adjustsFontForContentSizeCategory = true
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 112

        listControls.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(listControls)
        view.addSubview(tableView)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            listControls.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 8),
            listControls.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            listControls.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: listControls.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func updateControlsLayout() {
        let availableWidth = view.layoutMarginsGuide.layoutFrame.width
        let controlsWidth = filterButton.intrinsicContentSize.width + listControls.spacing
            + sortButton.intrinsicContentSize.width
        let usesLargeText = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        let usesVerticalLayout = usesLargeText || controlsWidth > availableWidth
        let axis: NSLayoutConstraint.Axis = usesVerticalLayout ? .vertical : .horizontal
        guard listControls.axis != axis else { return }
        listControls.axis = axis
        listControls.alignment = usesVerticalLayout ? .leading : .center
    }

    private func render(_ state: TaskViewModel.State) {
        filterButton.configuration?.title = state.filter.title
        filterButton.accessibilityValue = state.filter.title
        sortButton.configuration?.title = state.sortOrder.title
        sortButton.accessibilityValue = state.sortOrder.title
        view.setNeedsLayout()

        let priorityActions = TaskPriority.allCases.map { priority in
            filterAction(.priority(priority), selected: state.filter)
        }
        filterButton.menu = UIMenu(children: [
            filterAction(.all, selected: state.filter),
            filterAction(.completed, selected: state.filter),
            UIMenu(title: "По приоритету", children: priorityActions)
        ])
        sortButton.menu = UIMenu(children: TaskViewModel.SortOrder.allCases.map { order in
            UIAction(title: order.title, state: order == state.sortOrder ? .on : .off) { [weak self] _ in
                self?.viewModel.selectSortOrder(order)
            }
        })

        emptyLabel.text = state.emptyMessage
        tableView.backgroundView = state.rows.isEmpty ? emptyLabel : nil
        tableView.reloadData()
    }

    private func filterAction(
        _ filter: TaskViewModel.Filter,
        selected: TaskViewModel.Filter
    ) -> UIAction {
        UIAction(title: filter.title, state: selected == filter ? .on : .off) { [weak self] _ in
            self?.viewModel.selectFilter(filter)
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
}

extension TaskListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.state.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TaskCell.reuseIdentifier) as? TaskCell
            ?? TaskCell(style: .default, reuseIdentifier: TaskCell.reuseIdentifier)
        cell.configure(with: viewModel.state.rows[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.toggleCompletion(id: viewModel.state.rows[indexPath.row].id)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let taskID = viewModel.state.rows[indexPath.row].id
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, completion in
            completion(self?.viewModel.deleteTask(id: taskID) ?? false)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
