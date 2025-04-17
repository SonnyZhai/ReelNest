# ReelNest

A cross-platform online video search and viewing application built on Flutter.



## 📺 Overview

**This project is based on: `https://github.com/LibreSpark/LibreTV`**

  ReelNest is a cross-platform online video search and viewing application built on `Flutter`. It allows users to search for videos from various platforms, view them, and manage their watchlists. The app is designed to provide a seamless user experience across different devices.

  Using golang to build a cross-platform proxy server.



## ✨ Features

- **Multi-source Aggregation**: Integrates various video sources, with automatic deduplication and smart filtering.
- **Fast & Smooth**: Flutter frontend + Go backend for lightning-fast response and seamless user experience.
- **API Proxy**: Backend handles anti-crawling, data cleaning, and unifies data structure for the frontend.
- **Cross-platform**: Runs on Android, iOS, Web, Mac, and Windows.
- **Easy to Use & Extend**: Simple configuration, ready to run, and easy for secondary development.


## 🚀 Quick Start

### 1. Start Backend

```bash
cd backend
go mod tidy
go run .
```
Default port: `8080`

### 2. Run Frontend

```bash
cd reelnest
flutter pub get
flutter run
```

## ⚙️ Configuration

- **Backend**: `backend/config/config.go`
  Configure proxy port, and other settings. 
- **Frontend**: `scripts/json_to_dart.py`
  Configure the video source list. 


## ⚠️ Disclaimer
- This project is for educational purposes only. Please do not use it for commercial purposes.
- reelnest acts as a video search tool only and does not store, upload or distribute any video content. All videos come from search results provided by third-party API interfaces. For infringing content, please contact the appropriate content provider.
- No packaged mirrors are provided for this project. Please build it yourself.
- The project is not affiliated with any third-party video platform. All video content is provided by the respective platforms.

## 🤝 Contributing

Pull requests, issues, and stars are welcome!  

