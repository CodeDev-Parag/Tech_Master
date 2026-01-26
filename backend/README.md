# Task Master Data Collection Backend

This is a simple Dart server to collect training data from the Task Master app.

## Prerequisites
- Dart SDK installed

## How to Run
1. Open a terminal in this directory.
2. Run `dart pub get` to install dependencies.
3. Run `dart run server.dart` to start the server.

## Windows Shortcut
Double-click `run_server.bat` to start the server in a new window.

## Endpoints
- `POST /collect`: Accepts JSON training data.
- `GET /view`: Returns all collected data.
