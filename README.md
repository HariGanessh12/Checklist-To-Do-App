# Checklist App

Checklist App is a Flutter-based task management application for creating, organizing, and tracking tasks and task groups. It is designed to work offline with local storage, reminders, and a clean Material 3 interface.

## Overview

The app supports:

- Task and task group management
- Local sign-in and account switching
- Recurring tasks and completion rules
- Task reminders and notification scheduling
- Recycle bin support for deleted tasks and groups
- Productivity stats and home screen widgets
- Light and dark themes with animation toggles

## Features

### Core Workflow

- Create, edit, complete, pin, and delete tasks
- Create, edit, and delete task groups
- Move deleted items to a recycle bin and restore them later
- View tasks by today, upcoming, overdue, no due date, and streak filters
- Search and browse tasks across the app

### UX

- Material 3 UI
- Loading states for sign-in actions
- Clear SnackBar messages for validation and action feedback
- Responsive layouts using builder-based lists and grids
- Optional animation reduction through app settings

### Reminders and Automation

- Local notifications for task reminders
- Reminder scheduling based on task priority
- Recurrence support for daily, weekly, monthly, and custom intervals
- Home screen widget updates

### Local Data

- Offline-first storage using `shared_preferences`
- Scoped data per local account
- Local authentication state

## Tech Stack

- Flutter
- Dart
- Material 3
- `shared_preferences`
- `flutter_local_notifications`
- `timezone`
- `flutter_timezone`
- `uuid`
- `intl`

## Project Structure

- `lib/main.dart` - app bootstrap and routing
- `lib/core/` - theme and shared constants
- `lib/models/` - task and group models
- `lib/pages/` - app screens
- `lib/services/` - storage, notifications, recurrence, stats, and widget services
- `lib/widgets/` - reusable UI components and bottom sheets

## Setup

### Prerequisites

- Flutter SDK installed
- Dart SDK included with Flutter
- Android Studio, VS Code, or another Flutter-compatible editor
- Android emulator, iOS simulator, or physical device

### Install Dependencies

```bash
flutter pub get
```

### Run the App

```bash
flutter run
```

## Building

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle

```bash
flutter build appbundle --release
```

### Other Platforms

You can also build for other supported platforms with the standard Flutter commands, for example:

```bash
flutter build windows
flutter build macos
flutter build linux
```

## Notes

- This project currently uses local/offline storage instead of a remote API backend.
- README and build instructions can be expanded later if the app is connected to a server.
- Android release signing is currently configured for debug signing in the project file, so update signing settings before publishing to the Play Store.

## Useful Commands

```bash
flutter analyze
flutter test
flutter clean
```

