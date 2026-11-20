# TaskManager

TaskManager is a small iOS 17+ app built with Swift and UIKit.

## Features

1. Add a task with a title, an optional description, and a priority.
2. Swipe left to delete a task. The app identifies it by its `UUID`.
3. Tap a task to mark it complete or incomplete.
4. View all tasks.
5. View only completed tasks.
6. Filter tasks by priority.
7. Sort tasks by creation date, newest first, or keep them in the order they were added.

The app uses MVVM. `TaskViewModel` handles task actions, filtering, and sorting. `UserDefaultsTaskRepository` saves tasks locally between launches.

## Run

Open `TaskManager.xcodeproj` in Xcode, select the `TaskManager` scheme and an iOS simulator, then press **⌘R**. Press **⌘U** to run the unit tests.
