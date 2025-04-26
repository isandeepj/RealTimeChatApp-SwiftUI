//
//  ChatDetailView.swift
//  RealTimeChat
//
//  Created by Sandeep on 25/04/25.
//

import SwiftUI

struct ChatDetailView: View {
    @Binding var chat: Chat
    @ObservedObject var viewModel: ChatViewModel
    @State private var messageText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if chat.messages.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No messages yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(chat.messages) { message in
                                HStack(alignment: .bottom) {
                                    if message.isSentByUser {
                                        Spacer()
                                        Text(message.text)
                                            .padding(10)
                                            .background(message.isQueued ? Color.orange : Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    } else {
                                        Text(message.text)
                                            .padding(10)
                                            .background(Color.gray.opacity(0.3))
                                            .cornerRadius(10)
                                        Spacer()
                                    }
                                }
                                .id(message.id)
                                
                                HStack(spacing: 6) {
                                    if message.isSentByUser { Spacer() }
                                    
                                    Text(message.timestamp.formattedString)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                                                        
                                    if !message.isSentByUser { Spacer() }
                                }
                                .padding(.horizontal, message.isSentByUser ? 0 : 4)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: chat.messages.count) { _ , _ in
                        if let last = chat.messages.last?.id {
                            withAnimation {
                                scrollView.scrollTo(last, anchor: .bottom)
                            }
                        }
                        viewModel.markMessagesAsRead(for: chat)
                    }
                }
            }
            if !viewModel.isConnected {
                HStack(spacing: 6) {
                    Image(systemName: "wifi.slash")
                    Text("You're offline. Messages will be queued.")
                        .font(.footnote)
                        .foregroundColor(.red)
                }
                .padding(.bottom, 4)
            }
            
            if viewModel.isConnected && !viewModel.isSocketConnected {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Socket disconnected. Retrying...")
                        .font(.footnote)
                        .foregroundColor(.orange)
                }
                .padding(.bottom, 4)
            }
            
            Divider()
            HStack(spacing: 12) {
                TextField("Message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 10)
                    .focused($isTextFieldFocused)
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .rotationEffect(.degrees(45))
                        .padding(10)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            .background(Color(UIColor.secondarySystemGroupedBackground))
        }
        .gesture(
            TapGesture().onEnded { isTextFieldFocused = false }
        )
        .navigationTitle(chat.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        viewModel.selectChat(chat)
        viewModel.sendMessage(trimmed)
        messageText = ""
    }
}
