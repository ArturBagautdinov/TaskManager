import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let repository = UserDefaultsTaskRepository(defaults: .standard)
        let viewModel = TaskViewModel(repository: repository)
        let listViewController = TaskListViewController(viewModel: viewModel)
        listViewController.onAddTask = { [weak listViewController] in
            let addViewController = AddTaskViewController(viewModel: viewModel)
            let navigationController = UINavigationController(rootViewController: addViewController)
            listViewController?.present(navigationController, animated: true)
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: listViewController)
        self.window = window
        window.makeKeyAndVisible()
    }
}

