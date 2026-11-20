import Foundation

protocol TaskRepository {
    func loadTasks() throws -> [TaskItem]
    func insert(_ task: TaskItem) throws
    func update(id: UUID, change: (inout TaskItem) -> Void) throws
    func delete(id: UUID) throws
}

final class UserDefaultsTaskRepository: TaskRepository {
    static let storageKey = "TaskManager.tasks"

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func loadTasks() throws -> [TaskItem] {
        guard let storedValue = defaults.object(forKey: Self.storageKey) else {
            return []
        }
        guard let data = storedValue as? Data else {
            throw TaskError.cannotLoadTasks
        }

        do {
            return try JSONDecoder().decode([TaskItem].self, from: data)
        } catch {
            throw TaskError.cannotLoadTasks
        }
    }

    func insert(_ task: TaskItem) throws {
        var tasks = try loadTasks()
        tasks.append(task)
        try save(tasks)
    }

    func update(id: UUID, change: (inout TaskItem) -> Void) throws {
        var tasks = try loadTasks()
        let index = try taskIndex(id: id, in: tasks)
        change(&tasks[index])
        try save(tasks)
    }

    func delete(id: UUID) throws {
        var tasks = try loadTasks()
        let index = try taskIndex(id: id, in: tasks)
        tasks.remove(at: index)
        try save(tasks)
    }

    private func taskIndex(id: UUID, in tasks: [TaskItem]) throws -> Int {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            throw TaskError.taskNotFound(id: id)
        }
        return index
    }

    private func save(_ tasks: [TaskItem]) throws {
        let data: Data
        do {
            data = try JSONEncoder().encode(tasks)
        } catch {
            throw TaskError.cannotSaveTasks
        }
        defaults.set(data, forKey: Self.storageKey)
    }
}
