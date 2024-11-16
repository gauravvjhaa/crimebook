# 📱 CrimeBook

CrimeBook is a mobile application developed to make crime data more accessible and engaging for the general public, law enforcement, and researchers. By transforming raw crime data from trusted government sources into dynamic and interactive visualizations, CrimeBook empowers users to explore crime trends, hotspots, and patterns with ease.

---

## 🚀 Features

- **Interactive Data Visualizations**  
  Analyze crime data through dynamic and user-friendly charts powered by Syncfusion Flutter Charts.
- **Personalized News Feed and Alerts**  
  Receive real-time crime alerts based on user preferences and locality using the News API.
- **User Profile Management**  
  Customize news and alert preferences anytime to enhance your experience.
- **Secure Authentication**  
  Ensures data protection with Firebase Authentication and Firestore Cloud.
- **Cross-Platform Support**  
  Developed using Flutter, the app works seamlessly on both Android and iOS platforms.

---

## 🛠️ Technology Stack

### Frontend
- **Flutter**: Cross-platform framework for Android and iOS development.
- **Syncfusion Flutter Charts**: For interactive and visually appealing crime data charts.

### Backend
- **Firebase Authentication**: Secure user authentication.
- **Firestore Cloud**: Reliable cloud database for managing user data.
- **Flutter-Python API**: For advanced backend processing of data.

### APIs
- **News API**: Powers real-time personalized crime news and alerts.

---

## 📐 Architecture

1. **Frontend**: User interaction and visualization using Flutter.
2. **Backend**: Firebase for authentication and data storage.
3. **Processing API**: Python backend for advanced data processing.
4. **Data Visualization**: Syncfusion charts for user-friendly data display.

---

## 📲 Installation

### Pre-Requisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- Firebase Project Set Up
- News API Key ([Sign up here](https://newsapi.org/))

### Steps to Run
1. **Clone the Repository**
   ```bash
   git clone https://github.com/gauravvjhaa/crimebook.git
   cd CrimeBook
   
2. **Install Dependencies**
   ```bash
   flutter pub get
   
3. **Set Up Firebase**
    - Add your `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) in the respective folders.
    - Enable Authentication and Firestore in your Firebase Console.

4. **Add API Keys**
    - Create an `.env` file in the root directory.
   ```bash
   NEWS_API_KEY=your_api_key
   
5. **Run the App**
   ```bash
   flutter run

---

## 🖼️ Screenshots

### Admin Panel
![Admin Panel](screenshots/Admin.png)

### Authentication Screen
![Authentication Screen](screenshots/Auth.png)

### Dark Theme
![Dark Theme](screenshots/Dark.png)

### Light Theme
![Light Theme](screenshots/Light.png)

### Miscellaneous
![Miscellaneous](screenshots/Misc.png)

---

## 📝 Roadmap

- [x] Implement Firebase Authentication and Firestore Integration.
- [x] Set up Syncfusion Charts for visualizations.
- [ ] Add multi-language support.
- [ ] Enhance search functionality for crime trends.
- [ ] Introduce machine learning for predictive analytics on crime hotspots.

---

## 🤝 Contribution Guidelines

1. Fork the repository:
   ```bash
   git fork https://github.com/gauravvjhaa/crimebook.git

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature-name

3. **Commit Changes**
   ```bash
   git commit -m "Add a feature"

4. **Push to the Branch**
   ```bash
   git push origin feature-name

5. **Open a Pull Request on GitHub**
    - Navigate to your repository on GitHub.
    - Click the "Pull Requests" tab.
    - Click "New Pull Request."
    - Select your branch and create the pull request.

---

## 🛡️ License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

---

## 📫 Contact

For queries or feedback, contact:
```text
📧 gauravkumarjha306@cic.du.ac.in
📧 kjkrishnapoet27@gmail.com
📧 indiannikhil12@gmail.com
📧 vishwajeetnandyaduraj786@gmail.com
📧 rajshakya.orai18@gmail.com

