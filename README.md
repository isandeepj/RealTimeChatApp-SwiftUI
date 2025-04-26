# Real-Time Chat App

A lightweight real-time chat application built with SwiftUI, Combine, and WebSocket integration using PieSocket.

## Features
- Real-time messaging with socket connection (PieSocket)
- Offline message queuing and automatic retry when the network restored
- Dynamic chat list with unread message counts
- Socket reconnects when the app returns from the background
- Timestamps for each message (formatted display)
- Smart sorting: recent active chats float to the top
- Real-time network monitoring using NWPathMonitor
- Clean MVVM structure using Combine for reactive updates
- Dummy users and quick login options for testing

## Technologies
- Swift 5+
- SwiftUI
- Combine
- NWPathMonitor
- PieSocket WebSocket SDK

## Setup
1. Clone the repository:
    ```bash
    git clone https://github.com/isandeepj/RealTimeChatApp-SwiftUI.git
    cd RealTimeChat
    ```

2. Open in Xcode:
    ```bash
    open RealTimeChat.xcodeproj
    ```

3. Build and Run:
    - Select a Simulator or your iOS Device (iOS 17+).
    - Press `Cmd + R`.

> **Note:** The app connects to PieSocket's WebSocket server for real-time updates. No server setup needed.

## Project Structure

- `ViewModels/`: ChatViewModel manages sockets and chats
- `Views/`: SwiftUI screens for login, chat list, chat detail
- `Models/`: User, Chat, Message, Payload structures
- `Networking/`: PieSocket WebSocket manager abstraction
