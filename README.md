# Tech Master AI 🧠✅

**Tech Master** is an intelligent, privacy-focused productivity system that uses **Local Machine Learning** to predict task categories and priorities. It features a modern, premium aesthetic, note-taking capabilities, and scientifically-backed procrastination combat techniques.

![Tech Master App Icon](assets/images/app_icon.png)

## ✨ Key Features

*   **Diffused Intelligence:** Runs a Naive Bayes classifier *entirely on-device* to predict task metadata (Category & Priority) from natural language.
*   **Natural Language Parsing:** Type "Buy milk tomorrow at 5pm" or "Plan javascript in 2 days" and the app auto-extracts time and creates structured tasks.
*   **Conversational AI Assistant:** Suggests actions based on your task history and helps you build learning plans.
*   **Note-taking & Export:** Capture ideas and export them as high-quality **Images** or **PDFs**.
*   **Procrastination Combat:** Dedicated section with techniques like the **5-Second Rule**, **Pomodoro**, and **Eat the Frog**.
*   **Privacy First:** All personal data stays on your device. Only anonymized "model weights" are shared if you opt-in.
*   **Federated Learning Backend:** A Dart-based backend collects anonymized insights to build a global "Super Model".
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
