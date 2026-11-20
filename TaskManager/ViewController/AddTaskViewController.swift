import UIKit

final class AddTaskViewController: UIViewController {
    private let viewModel: TaskViewModel
    private let formView = AddTaskView(frame: .zero)

    init(viewModel: TaskViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }

    override func loadView() {
        view = formView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Новая задача"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Отмена", style: .plain, target: self, action: #selector(cancel)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Сохранить", style: .done, target: self, action: #selector(save)
        )
    }

    @objc private func save() {
        viewModel.save(
            title: formView.taskTitle,
            details: formView.details,
            priority: formView.priority,
            onResult: handleSaveResult
        )
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    private func handleSaveResult(_ result: TaskViewModel.SaveResult) {
        switch result {
        case .failed(let message):
            let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ОК", style: .default))
            present(alert, animated: true)
        case .saved:
            dismiss(animated: true)
        }
    }
}
