import Foundation

@MainActor
final class TaskViewModel {
    enum Filter: Equatable {
        case all
        case completed
        case priority(TaskPriority)

        var title: String {
            switch self {
            case .all: return "Все задачи"
            case .completed: return "Завершённые"
            case .priority(let priority): return priority.displayTitle
            }
        }
    }

    enum SortOrder: CaseIterable {
        case insertion
        case newestFirst

        var title: String {
            switch self {
            case .insertion: return "По добавлению"
            case .newestFirst: return "Сначала новые"
            }
        }
    }

    struct Row {
        let id: UUID
        let title: String
        let details: String
        let creationDateText: String
        let priority: TaskPriority
        let isCompleted: Bool

        var priorityText: String { "\(priority.displayTitle) приоритет" }

        var statusText: String {
            isCompleted ? "Завершена" : "Не завершена"
        }
    }

    struct State {
        let filter: Filter
        let sortOrder: SortOrder
        let rows: [Row]
        var emptyMessage = "Задач нет"
    }

    enum SaveResult: Equatable {
        case saved
        case failed(message: String)
    }

    private let repository: TaskRepository
    private let now: () -> Date
    private let dateFormatter: DateFormatter
    private(set) var state = State(filter: .all, sortOrder: .insertion, rows: []) {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((State) -> Void)?
    var onError: ((String) -> Void)?

    init(repository: TaskRepository, now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.now = now

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        self.dateFormatter = dateFormatter
    }

    func refresh() {
        refresh(filter: state.filter, sortOrder: state.sortOrder)
    }

    func selectFilter(_ filter: Filter) {
        refresh(filter: filter, sortOrder: state.sortOrder)
    }

    func selectSortOrder(_ sortOrder: SortOrder) {
        refresh(filter: state.filter, sortOrder: sortOrder)
    }

    private func refresh(filter: Filter, sortOrder: SortOrder) {
        do {
            let allTasks = try repository.loadTasks()
            let filteredTasks: [TaskItem]
            switch filter {
            case .all:
                filteredTasks = allTasks
            case .completed:
                filteredTasks = allTasks.filter(\.isCompleted)
            case .priority(let priority):
                filteredTasks = allTasks.filter { $0.priority == priority }
            }

            let tasks = sortOrder == .newestFirst
                ? filteredTasks.reversed().sorted { $0.createdAt > $1.createdAt }
                : filteredTasks
            let rows = tasks.map { task in
                Row(
                    id: task.id,
                    title: task.title,
                    details: task.details,
                    creationDateText: "Создано \(dateFormatter.string(from: task.createdAt))",
                    priority: task.priority,
                    isCompleted: task.isCompleted
                )
            }
            state = State(filter: filter, sortOrder: sortOrder, rows: rows)
        } catch {
            state = State(filter: filter, sortOrder: sortOrder, rows: [], emptyMessage: error.localizedDescription)
        }
    }

    func save(
        title: String,
        details: String,
        priority: TaskPriority = .defaultPriority,
        onResult: (SaveResult) -> Void
    ) {
        do {
            let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { throw TaskError.emptyTitle }

            let task = TaskItem(
                id: UUID(),
                title: title,
                details: details,
                createdAt: now(),
                priority: priority,
                isCompleted: false
            )
            try repository.insert(task)
            refresh()
            onResult(.saved)
        } catch {
            onResult(.failed(message: error.localizedDescription))
        }
    }

    func toggleCompletion(id: UUID) {
        do {
            try repository.update(id: id) { task in
                task.isCompleted.toggle()
            }
            refresh()
        } catch {
            onError?(error.localizedDescription)
        }
    }

    func deleteTask(id: UUID) -> Bool {
        do {
            try repository.delete(id: id)
            refresh()
            return true
        } catch {
            onError?(error.localizedDescription)
            return false
        }
    }
}
