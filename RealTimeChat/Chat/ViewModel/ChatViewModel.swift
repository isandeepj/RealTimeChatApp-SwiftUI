//
//  ChatViewModel.swift
//  RealTimeChat
//
//  Created by Sandeep on 25/04/25.
//

import Foundation
import Combine
import Network
import UIKit

class ChatViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var selectedChat: Chat?
    @Published var isConnected: Bool = true
    @Published var isSocketConnected: Bool = true
    @Published var currentUser: User? {
        didSet {
            if let user = currentUser {
                UserDefaults.standard.set(user.id, forKey: "lastUserId")
            }
        }
    }
    
    var sortedChats: [Chat] {
        chats.sorted { ($0.messages.last?.timestamp ?? Date.distantPast) > ($1.messages.last?.timestamp ?? Date.distantPast) }
    }

    let dummyUsers: [User] = [
        User(id: "1", name: "Alice"),
        User(id: "2", name: "Bob"),
        User(id: "3", name: "Charlie")
    ]
    
    private var cancellables = Set<AnyCancellable>()
    private var queuedMessages: [Message] = []
    private let retryQueue = DispatchQueue(label: "RetryQueue")
    private var debounceRetryWorkItem: DispatchWorkItem?

    private let roomId = "chat-room"
    init() {
        tryAutoLogin()
        setupBindings()
    }
    
    func tryAutoLogin() {
        if let savedId = UserDefaults.standard.string(forKey: "lastUserId"),
           let savedUser = dummyUsers.first(where: { $0.id == savedId }) {
            login(as: savedUser)
        }
    }
    
    func login(as user: User) {
        self.isConnected = NetworkStatusMonitor.shared.isConnected
        currentUser = user
        setupSocket()
        seedDummyChats(for: user)
    }
    
    private func seedDummyChats(for user: User) {
        chats = dummyUsers
            .filter { $0.id != user.id }
            .map { Chat(participant: $0) }
    }
    
    func selectChat(_ chat: Chat) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            selectedChat = chats[index]
            markMessagesAsRead(for: chats[index])
        }
    }
    
    func clearSelectedChat() {
        selectedChat = nil
    }
    
    func sendMessage(_ text: String) {
        guard let currentUser = currentUser, var selected = selectedChat else { return }
        let message = Message(text: text, timestamp: .now, isSentByUser: true, sender: currentUser, receiver: selected.participant)
        
        if isSocketConnected && isConnected {
            let payload = PublicMessagePayload(
                text: message.text,
                senderId: message.sender.id,
                receiverId: message.receiver.id
            )
            PieSocketManager.shared.publish(to: roomId, payload: payload)
        } else {
            var queued = message
            queued.isQueued = true
            queuedMessages.append(queued)
        }
        
        selected.messages.append(message)
        updateChat(selected)
    }
    
    func receiveMessage(_ message: Message) {
        let isActive = selectedChat?.participant == message.sender
        
        if let index = chats.firstIndex(where: { $0.participant == message.sender }) {
            var chat = chats.remove(at: index)
            chat.messages.append(message)
            
            if isActive {
                chat.lastReadMessageId = message.id
            }
            
            chat.updateMessageCounts()
            chats.insert(chat, at: 0)

            if isActive {
                selectedChat = chat
            }

        } else {
            var newChat = Chat(participant: message.sender, messages: [message], lastReadMessageId: isActive ? message.id : nil)
            if isActive {
                newChat.lastReadMessageId = message.id
            }
            
            newChat.updateMessageCounts()
            chats.insert(newChat, at: 0)
            
            if isActive {
                selectedChat = newChat
            }
        }
    }
    
    func markMessagesAsRead(for chat: Chat) {
        guard let index = chats.firstIndex(where: { $0.id == chat.id }) else { return }
        
        let lastMessage = chats[index].messages.last(where: { !$0.isSentByUser })
        chats[index].lastReadMessageId = lastMessage?.id
        chats[index].updateMessageCounts()
        if selectedChat?.id == chat.id {
            selectedChat = chats[index]  // Update selection if needed
        }
    }
    
    private func updateChat(_ chat: Chat) {
        if let index = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[index] = chat
            selectedChat = chat
        }
    }
    
    private func setupBindings() {
        NetworkStatusMonitor.shared.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                let isNetworkConnected = status.0
                self.isConnected = isNetworkConnected
                print("Network connected: \(isNetworkConnected)")
                
                if isNetworkConnected && self.isSocketConnected {
                    self.scheduleRetryQueuedMessages()
                }
                
                if isNetworkConnected && !self.isSocketConnected {
                    self.reconnectSocketIfNeeded()
                }
            }
            .store(in: &cancellables)
        
        PieSocketManager.shared.socketStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSocketConnected in
                guard let self = self else { return }
                self.isSocketConnected = isSocketConnected
                print("Socket connected: \(isSocketConnected)")
                
                if self.isConnected && isSocketConnected {
                    self.scheduleRetryQueuedMessages()
                }
            }
            .store(in: &cancellables)
    }


    private func setupSocket() {
        guard let userId = currentUser?.id else { return }

        PieSocketManager.shared.connect(roomId: roomId, userId: userId)

        PieSocketManager.shared.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                self?.handleIncoming(payload)
            }
            .store(in: &cancellables)
    }

    private func handleIncoming(_ payload: PublicMessagePayload) {
        guard let currentUser = self.currentUser else { return }
        
        // If this message is not for me, ignore it
        if payload.receiverId != currentUser.id && payload.senderId != currentUser.id {
            return
        }
        
        let isSelfMessage = payload.senderId == currentUser.id
        guard isSelfMessage == false else { return }
        var sender = self.chats.first(where: { $0.participant.id == payload.receiverId || $0.participant.id == payload.senderId })?.participant
        
        if sender == nil {
            sender = self.dummyUsers.first(where: { $0.id == payload.receiverId })
            if let sender = sender {
                self.startNewChat(with: sender)
            }
        }
        
        guard let finalSender = sender else { return }
        
        let message = Message(
            text: payload.text,
            timestamp: Date.now,
            isSentByUser: false,
            sender: finalSender,
            receiver: currentUser
        )
        self.receiveMessage(message)
    }
    
    func reconnectSocketIfNeeded() {
        guard currentUser != nil else { return }
        if !isSocketConnected {
            PieSocketManager.shared.reconnect(roomId: roomId)
        }
    }

    func disconnectSocketIfNeeded() {
        PieSocketManager.shared.disconnect(roomId: roomId)
    }
     

    private func retryQueuedMessages() {
        retryQueue.async { [weak self] in
            guard let self = self, self.isConnected, self.isSocketConnected, !self.queuedMessages.isEmpty else { return }

            for message in self.queuedMessages {
                let payload = PublicMessagePayload(
                    text: message.text,
                    senderId: message.sender.id,
                    receiverId: message.receiver.id
                )
                PieSocketManager.shared.publish(to: roomId, payload: payload)
            }

            self.queuedMessages.removeAll()
        }
    }
    
    private func scheduleRetryQueuedMessages(after delay: TimeInterval = 0.3) {
        debounceRetryWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.retryQueuedMessages()
        }
        debounceRetryWorkItem = workItem
        retryQueue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    
    func logout() {
        currentUser = nil
        chats = []
        selectedChat = nil
        PieSocketManager.shared.disconnectAll()
        UserDefaults.standard.removeObject(forKey: "lastUserId")
        cancellables.removeAll()
    }
    
    func startNewChat(with user: User) {
        if !chats.contains(where: { $0.participant == user }) {
            chats.append(Chat(participant: user))
        }
    }
}
