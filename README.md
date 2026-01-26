# Task Master AI 🧠✅

**Task Master** is an intelligent, privacy-focused task management application that uses **Local Machine Learning** to predict task categories and priorities. It features a modern, premium "Dark Mode" aesthetic and offers optional federated learning to improve its intelligence over time.

![Task Master App Icon](assets/images/app_icon.png)

## ✨ Key Features

*   **Diffused Intelligence:** Runs a Naive Bayes classifier *entirely on-device* to predict task metadata (Category & Priority) from natural language.
*   **Natural Language Parsing:** Type "Buy milk tomorrow at 5pm" and the app auto-extracts the Date, Time, and Task Title.
*   **Smart Suggestions:** The AI Chat Assistant suggests actions based on your task history and current workload.
*   **Privacy First:** All personal data stays on your device. Only anonymized "model weights" (word counts) are shared if you opt-in to Continuous Learning.
*   **Federated Learning Backend:** A Dart-based backend collects anonymized insights to build a global "Super Model" that improves the app for everyone.
*   **Gamification:** Earn streaks and productivity scores as you complete tasks.

## 🛠 Tech Stack

*   **Frontend:** Flutter (Mobile, Web, Desktop)
*   **State Management:** Riverpod 2.0
*   **Database:** Hive (NoSQL, Local)
*   **Backend:** Dart Shelf (Server)
*   **Deployment:** Docker + Render / Google Cloud Run
*   **Design:** Custom Dark Mode Theme with Glassmorphism elements.

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (3.0+)
*   Dart SDK

### Running the App
1.  Clone the repository:
    ```bash
    git clone https://github.com/CodeDev-Parag/Tech_Master.git
    cd task_master
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the app:
    ```bash
    flutter run
    ```

### Running the Backend (Optional)
If you want to host your own Learning Server:
1.  Navigate to the backend:
    ```bash
    cd backend
    ```
2.  Run the server locally:
    ```bash
    dart run server.dart
    ```
    *Server listens on port 8080 by default.*

## ☁️ Deployment

The backend is containerized with Docker.
```bash
docker build -t task-master-backend .
docker run -p 8080:8080 task-master-backend
```
It is currently deployed on **Render**.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is open-source.
