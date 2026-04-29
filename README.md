# Material Tasks

Material Tasks is an offline-first Flutter productivity app for creating, organizing, and tracking personal tasks with reminders, recurring schedules, local account support, and backup import/export tools.

## Overview

The app helps users manage daily work through a clean Material 3 interface, smart local reminders, grouped task organization, and productivity-focused views such as today, upcoming, overdue, no due date, and streak-based tasks.

## Features

- Create, edit, pin, complete, and delete tasks
- Organize tasks into custom groups
- Track subtasks inside a parent task
- Use recurring and streak-based task flows
- Filter tasks by Today, All, Upcoming, Overdue, No Due Date, and Streaks
- Schedule local notifications with snooze actions
- Store data locally for offline use
- Support local sign-in and account-based scoped data
- Restore deleted tasks and groups from a recycle bin
- Import tasks from `JSON` or `CSV`
- Export full local backups as `JSON`
- View productivity stats and reminder management screens
- Update Android home screen widgets for task visibility
- Switch between system, light, and dark themes
- Toggle smooth animations from settings

## Tech Stack

- **Flutter**: Cross-platform UI toolkit used to build the mobile, desktop, and web app from a single codebase
- **Dart**: Primary programming language used for UI, models, and business logic
- **Material 3**: Design system used for the app's modern, consistent user interface
- **Shared Preferences**: Local persistent storage for tasks, groups, settings, reminder presets, and account-scoped data
- **flutter_local_notifications**: Schedules and manages on-device reminder notifications
- **timezone**: Ensures reminders are scheduled using correct local time zones
- **flutter_timezone**: Detects the device timezone for accurate reminder handling
- **file_picker**: Supports importing task files and saving local backup exports
- **uuid**: Generates stable unique identifiers for tasks and groups
- **intl**: Formats dates and task-related time information for display

## Folder Structure

```text
checklist_app/
|-- lib/
|   |-- core/        # Theme, constants, and shared app configuration
|   |-- models/      # Task and task group data models
|   |-- pages/       # Main app screens
|   |-- services/    # Storage, notifications, recurrence, stats, import/export
|   `-- widgets/     # Reusable UI widgets and bottom sheets
|-- android/         # Android-specific configuration and widgets
|-- ios/             # iOS runner files
|-- macos/           # macOS runner files
|-- linux/           # Linux runner files
|-- windows/         # Windows runner files
|-- web/             # Web entry files and manifest
`-- pubspec.yaml     # Dependencies and Flutter configuration
```

## Installation

### Prerequisites

- Flutter SDK installed
- Dart SDK included with Flutter
- Android Studio, VS Code, or another Flutter-compatible IDE
- At least one configured target device or emulator

### Steps

1. Clone the repository:

```bash
git clone <your-repository-url>
cd checklist_app
```

2. Install dependencies:

```bash
flutter pub get
```

3. Verify Flutter setup:

```bash
flutter doctor
```

## Run Commands

### Run in debug mode

```bash
flutter run
```

### Run on a specific device

```bash
flutter devices
flutter run -d <device_id>
```

### Build release binaries

```bash
flutter build apk --release
flutter build appbundle --release
flutter build windows
flutter build macos
flutter build linux
flutter build web
```

### Quality checks

```bash
flutter analyze
flutter test
```

## Environment Variables

This project currently does not require any environment variables.

Because the app is offline-first, user data is stored locally on-device using `shared_preferences`.

## Platform Notes

- Notification permissions are requested in-app when needed
- Android exact alarm permission may be requested for precise reminder scheduling
- Android home screen widgets are supported through native widget integrations

## Screenshots

Add product screenshots here when available.

```md
![Home Screen](path/to/home-screen.png)
![Task Detail](path/to/task-detail.png)
![Settings](path/to/settings.png)
```

## Future Improvements

- Cloud sync and remote backup support
- Richer authentication beyond local account storage
- Push notifications and cross-device reminder sync
- Better analytics dashboards and habit insights
- Drag-and-drop task reordering
- Expanded widget customization

## Contribution Guidelines

Contributions are welcome.

1. Fork the repository
2. Create a feature branch
3. Make your changes with clear commit messages
4. Run `flutter analyze` and `flutter test`
5. Open a pull request with a short summary of what changed

## License

This project is licensed under the MIT License.
