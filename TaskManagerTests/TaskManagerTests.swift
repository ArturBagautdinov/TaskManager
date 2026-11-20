
import Foundation
import Testing
@testable import TaskManager

final class TaskManagerTests {
    private let suiteName: String
    private let defaults: UserDefaults

    init() throws {
        let suiteName = "TaskManagerTests.\(UUID().uuidString)"
        self.suiteName = suiteName
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    @Test func addingTasksCreatesUniqueIDsAndAppliesDefaults() throws {
        let date = Date(timeIntervalSince1970: 100)
        let repository = UserDefaultsTaskRepository(defaults: defaults)
        let viewModel = TaskViewModel(repository: repository, now: { date })
        #expect(try repository.loadTasks().isEmpty)

        viewModel.save(title: "  Первая задача\n", details: "") {
            #expect($0 == .saved)
        }
        viewModel.save(title: "Первая задача", details: "Описание", priority: .low) {
            #expect($0 == .saved)
        }

        let tasks = try repository.loadTasks()
        #expect(tasks.map(\.title) == ["Первая задача", "Первая задача"])
        #expect(tasks.map(\.details) == ["", "Описание"])
        #expect(tasks.map(\.priority) == [.medium, .low])
        #expect(tasks.map(\.createdAt) == [date, date])
        #expect(tasks.allSatisfy { !$0.isCompleted })
        #expect(Set(tasks.map(\.id)).count == 2)
    }

    @MainActor
    @Test func filtersAndDateSortPreserveTheOriginalList() throws {
        var date = Date(timeIntervalSince1970: 300)
        let repository = UserDefaultsTaskRepository(defaults: defaults)
        let viewModel = TaskViewModel(repository: repository, now: { date })
        viewModel.save(title: "Новая", details: "", priority: .high) {
            #expect($0 == .saved)
        }
        date = Date(timeIntervalSince1970: 100)
        viewModel.save(title: "Старая", details: "", priority: .low) {
            #expect($0 == .saved)
        }
        date = Date(timeIntervalSince1970: 200)
        viewModel.save(title: "Средняя", details: "", priority: .medium) {
            #expect($0 == .saved)
        }
        date = Date(timeIntervalSince1970: 400)
        viewModel.save(title: "Новейшая", details: "", priority: .high) {
            #expect($0 == .saved)
        }

        let original = try repository.loadTasks()
        let completedTask = try #require(original.first)
        viewModel.toggleCompletion(id: completedTask.id)

        viewModel.selectFilter(.completed)
        #expect(viewModel.state.rows.map(\.id) == [completedTask.id])
        viewModel.selectFilter(.priority(.low))
        #expect(viewModel.state.rows.map(\.title) == ["Старая"])
        viewModel.selectFilter(.priority(.medium))
        #expect(viewModel.state.rows.map(\.title) == ["Средняя"])
        viewModel.selectFilter(.priority(.high))
        #expect(viewModel.state.rows.map(\.title) == ["Новая", "Новейшая"])
        viewModel.selectSortOrder(.newestFirst)
        #expect(viewModel.state.rows.map(\.title) == ["Новейшая", "Новая"])
        viewModel.selectFilter(.all)
        #expect(viewModel.state.rows.map(\.title) == ["Новейшая", "Новая", "Средняя", "Старая"])
        viewModel.selectSortOrder(.insertion)
        #expect(viewModel.state.rows.map(\.id) == original.map(\.id))

        let allTasks = try repository.loadTasks()
        #expect(allTasks.map(\.id) == original.map(\.id))
        #expect(allTasks.map(\.createdAt) == original.map(\.createdAt))
        #expect(allTasks.map(\.isCompleted) == [true, false, false, false])
    }

    @MainActor
    @Test func rejectsEmptyTitlesAndUnknownIDs() throws {
        let repository = UserDefaultsTaskRepository(defaults: defaults)
        let viewModel = TaskViewModel(repository: repository)
        for title in ["", " \t\n "] {
            viewModel.save(title: title, details: "Описание") {
                #expect($0 == .failed(message: TaskError.emptyTitle.localizedDescription))
            }
        }
        #expect(try repository.loadTasks().isEmpty)

        viewModel.save(title: "Задача", details: "") {
            #expect($0 == .saved)
        }
        let task = try #require(try repository.loadTasks().first)
        let unknownID = UUID()
        #expect(throws: TaskError.taskNotFound(id: unknownID)) {
            try repository.delete(id: unknownID)
        }
        #expect(throws: TaskError.taskNotFound(id: unknownID)) {
            try repository.update(id: unknownID) { $0.isCompleted = true }
        }
        let tasks = try repository.loadTasks()
        #expect(tasks.map(\.id) == [task.id])
        #expect(tasks.map(\.isCompleted) == [false])
    }

    @MainActor
    @Test func mutationsKeepTheSelectedFilterAndSortOrder() throws {
        let repository = UserDefaultsTaskRepository(defaults: defaults)
        let viewModel = TaskViewModel(repository: repository)
        var saveResults: [TaskViewModel.SaveResult] = []

        viewModel.selectFilter(.priority(.high))
        viewModel.selectSortOrder(.newestFirst)
        viewModel.save(title: "Низкий приоритет", details: "", priority: .low) {
            saveResults.append($0)
        }
        #expect(viewModel.state.rows.isEmpty)

        viewModel.save(title: "Высокий приоритет", details: "", priority: .high) {
            saveResults.append($0)
        }
        #expect(saveResults == [.saved, .saved])
        #expect(viewModel.state.filter == .priority(.high))
        #expect(viewModel.state.rows.map(\.title) == ["Высокий приоритет"])
        let highPriorityRow = try #require(viewModel.state.rows.first)
        #expect(viewModel.deleteTask(id: highPriorityRow.id))
        #expect(viewModel.state.filter == .priority(.high))
        #expect(viewModel.state.rows.isEmpty)

        viewModel.selectFilter(.all)
        #expect(viewModel.state.rows.map(\.title) == ["Низкий приоритет"])
        let remainingRow = try #require(viewModel.state.rows.first)
        viewModel.toggleCompletion(id: remainingRow.id)
        viewModel.selectFilter(.completed)
        let completedRow = try #require(viewModel.state.rows.first)
        #expect(completedRow.id == remainingRow.id)
        viewModel.toggleCompletion(id: completedRow.id)
        #expect(viewModel.state.filter == .completed)
        #expect(viewModel.state.sortOrder == .newestFirst)
        #expect(viewModel.state.rows.isEmpty)
        let tasks = try repository.loadTasks()
        #expect(tasks.map(\.id) == [remainingRow.id])
        #expect(tasks.map(\.isCompleted) == [false])
    }

    @Test func persistsTaskFieldsStatusAndDeletion() throws {
        let date = Date(timeIntervalSince1970: 100.5)
        let repository = UserDefaultsTaskRepository(defaults: defaults)
        let firstTask = TaskItem(
            id: UUID(), title: "Первая", details: "Описание",
            createdAt: date, priority: .high, isCompleted: false
        )
        let secondTask = TaskItem(
            id: UUID(), title: "Вторая", details: "",
            createdAt: date, priority: .low, isCompleted: false
        )
        try repository.insert(firstTask)
        try repository.insert(secondTask)

        let reopened = UserDefaultsTaskRepository(defaults: defaults)
        #expect(try reopened.loadTasks().map(\.id) == [firstTask.id, secondTask.id])
        try reopened.update(id: firstTask.id) { $0.isCompleted = true }
        try reopened.delete(id: secondTask.id)

        let restoredTasks = try UserDefaultsTaskRepository(defaults: defaults).loadTasks()
        let restored = try #require(restoredTasks.first)
        #expect(restoredTasks.count == 1)
        #expect(restored.id == firstTask.id)
        #expect(restored.title == "Первая")
        #expect(restored.details == "Описание")
        #expect(restored.createdAt == date)
        #expect(restored.priority == .high)
        #expect(restored.isCompleted)
    }

    @MainActor
    @Test func preservesUnreadableSavedData() {
        let invalidData = Data("invalid JSON".utf8)
        defaults.set(invalidData, forKey: UserDefaultsTaskRepository.storageKey)
        let repository = UserDefaultsTaskRepository(defaults: defaults)
        let viewModel = TaskViewModel(repository: repository)
        let message = TaskError.cannotLoadTasks.localizedDescription

        viewModel.refresh()
        #expect(viewModel.state.rows.isEmpty)
        #expect(viewModel.state.emptyMessage == message)
        viewModel.save(title: "Новая задача", details: "") {
            #expect($0 == .failed(message: message))
        }
        #expect(defaults.data(forKey: UserDefaultsTaskRepository.storageKey) == invalidData)
    }
}
