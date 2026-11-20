import Foundation

enum TaskError: LocalizedError, Equatable {
    case emptyTitle
    case taskNotFound(id: UUID)
    case cannotLoadTasks
    case cannotSaveTasks

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Введите название задачи."
        case .taskNotFound:
            return "Задача не найдена."
        case .cannotLoadTasks:
            return "Не удалось загрузить сохранённые задачи."
        case .cannotSaveTasks:
            return "Не удалось сохранить задачи."
        }
    }
}
