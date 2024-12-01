![appstore](https://github.com/user-attachments/assets/300591ee-933c-4227-9467-c4e8af6736f3)

# 📱 Khuje Nao - A Flutter App for Finding Lost Items in North South University
**📖 Overview** <br>
Khuje Nao is a Flutter-based mobile application designed to help users report and find lost items. Users can sign up, log in, chat with other users, and report lost items with details and images. It features a clean UI and integrates with a backend API for real-time data management.

## ✨ Features
* 🔐 User Authentication: Sign up, log in, and log out securely using an API.
* 💬 Chat Functionality: Communicate with others in real-time via a chat interface.
* 📄 Lost Item Reporting: Submit detailed reports for lost items, including images and location.
* 🔍 Search Functionality: Search for lost items using keywords.
* 🌐 Multi-language Support: Choose between different languages (English, Bangla, etc.).
* 📧 Email Notifications: Notify users about updates and newly reported items.

## 🛠️ Technologies Used
* Flutter (Frontend)
* Dart (Programming Language)
* HTTP (API Calls)
* Flutter Secure Storage (For securely storing user data)
* Awesome Notifications (For push notifications)
* Backend API (Flask backend)

## 🚀 Getting Started
* [Flutter SDK](https://flutter.dev/)
* [Dart](https://dart.dev/)
* [Python](https://docs.python.org/3/)
* [Flask](https://flask.palletsprojects.com/en/stable/)
* A connected mobile device or emulator (You can use [Android Studio](https://developer.android.com/studio))

### Installation
```
git clone https://github.com/yourusername/khuje-nao.git
cd khuje-nao
```
### Install dependencies
```
flutter pub get
```
### Run the app
```
flutter run
```
### Backend imports
```
Use 'pip install -r requirements.txt' to install backend dependencies
```

### Backend SendGrid API
[SendGrid](https://sendgrid.com/en-us) is needed for sending OTP.
Create .env file at backend to have these:
```
export SENDGRID_API_KEY='Your key'
export SENDGRID_EMAIL='Your email'
```

## 📁 Project Structure
Frontend App
```
├── lib
│   ├── main.dart              # Entry point of the app
│   ├── screens/               # UI screens like Login, Signup, Chat
│   ├── services/              # API services and business logic
│   ├── widgets/               # Reusable widgets
│   ├── localization/          # Language-specific strings
│   └── models/                # Data models (User, Message, etc.)
├── assets/                    # Images and static files
├── android/
├── doc
├── backend
└── test/                      # Unit and widget tests
```
Backend Server
```
backend/
├── app/
│   ├── __init__.py       # Application factory and initialization
│   ├── models.py         # Database models
│   ├── utils.py          # Utility functions
│   └── views.py          # API routes and request handling
├── static/               # Static files (images, stylesheets, etc.)
├── docs/
├── tests/
├── .env                  # Environment variables (API keys, DB configs)
├── .gitignore            # Files to be ignored by Git
├── config.py             # Configuration settings (dev, prod)
├── requirements.txt      # Downloading dependencies
└── run.py                # Entry point to start the Flask application
```

## 🧪 Running Tests
```
flutter test
```
## 📮 API Endpoints
<table>
  <thead>
    <tr><th>Endpoint</th><th>Method</th><th>Description</th></tr></thead>
  <tbody><tr><td><code>/signup</code></td><td>POST</td>
    <td>Sign up a new user</td></tr><tr><td><code>/login</code></td><td>POST</td><td>Log in an existing user</td></tr><tr><td><code>/lost-item</code></td><td>POST</td><td>Report a lost item</td></tr>
    <tr><td><code>/search-lost-items</code></td><td>GET</td><td>Search for lost items</td></tr>
    <tr><td><code>/send-message</code></td><td>POST</td><td>Send message</td></tr>
    <tr><td><code>/get-messages</code></td><td>GET</td><td>Get messages</td></tr>
    <tr><td><code>/get-chats</code></td><td>GET</td><td>Get the latest message for each chat</td></tr>
    <tr><td><code>/found-items</code></td><td>GET</td><td>Get found items</td></tr>
    <tr><td><code>/activity-feed</code></td><td>GET</td><td>Get activity feed</td></tr>
    <tr><td><code>/lost-items</code></td><td>GET</td><td>Get lost items</td></tr>
    <tr><td><code>/lost-items-admin</code></td><td>GET</td><td>Get lost items for admin approval</td></tr>
    <tr><td><code>/lost-items/<item_id>/approve</code></td><td>POST</td><td>Approve lost items (Admin)</td></tr>
    <tr><td><code>/send_lost_items_email</code></td><td>POST</td><td>Sends email to users about lost items</td></tr>
    <tr><td><code>/lost-items/item_id/found</code></td><td>POST</td><td>Mark lost items as found</td></tr>
    <tr><td><code>/send_otp</code></td><td>POST</td><td>Send OTP for verification</td></tr><tr><td><code>/verify_otp</code></td><td>POST</td><td>Verify OTP</td></tr>
    </tbody>
</table>
      
## 🧑‍💻 Contributors
<div style="display: inline-block; position: relative; width: 50px; height: 50px; overflow: hidden; border-radius: 50%; border: 2px solid #ddd;">
  <a href="https://github.com/Mostakim52">
    <img src="https://avatars.githubusercontent.com/u/104221451?v=4" style="width: 10%; height: 10%; object-fit: cover;">
  </a>
  <a href="https://github.com/Emran-Emon">
    <img src="https://avatars.githubusercontent.com/u/97731993?v=4" style="width: 10%; height: 10%; object-fit: cover;">
  </a>
  <a href="https://github.com/Md-Musfiq-Hossain">
    <img src="https://avatars.githubusercontent.com/u/160261648?v=4" style="width: 10%; height: 10%; object-fit: cover;">
  </a>
  <a href="https://github.com/RPAhNaf">
    <img src="https://avatars.githubusercontent.com/u/160027571?v=4" style="width: 10%; height: 10%; object-fit: cover;">
  </a>
</div>


## 📝 Feedback
If you have any suggestions or issues, feel free to open an issue on GitHub or reach out at guyawesome96@gmail.com.
