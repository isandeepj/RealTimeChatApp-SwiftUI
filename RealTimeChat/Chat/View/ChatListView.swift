//
//  ChatListView.swift
//  RealTimeChat
//
//  Created by Sandeep on 25/04/25.
//

import SwiftUI

struct ChatListView: View {
    @ObservedObject var viewModel: ChatViewModel
    
    @State private var showCreateChat = false
    
    var body: some View {
        NavigationView {
            VStack {
                if !viewModel.isConnected {
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text("You're offline or disconnected")
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                }
                if viewModel.chats.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "message")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No conversations yet")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.sortedChats, id: \.id) { chat in
                            if let chatBinding = binding(for: chat) {
                                NavigationLink(
                                    destination: ChatDetailView(chat: chatBinding, viewModel: viewModel)
                                        .onAppear {
                                            viewModel.selectChat(chatBinding.wrappedValue)
                                        }
                                        .onDisappear {
                                            viewModel.clearSelectedChat()
                                        }
                                ) {
                                    chatRow(for: chat)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        viewModel.logout()
                    }
                    
                    Button(action: {
                        showCreateChat = true
                    }) {
                        Image(systemName: "plus.message")
                    }
                }
            }
            .sheet(isPresented: $showCreateChat) {
                CreateChatView(viewModel: viewModel)
            }
        }
    }

    
    @ViewBuilder
    private func chatRow(for chat: Chat) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.name).bold()
                Text(chat.lastMessagePreview)
                    .lineLimit(1)
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
            
            Spacer()
            
            if chat.unreadCount > 0 {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.8))
                        .frame(width: 24, height: 24)
                    Text(chat.unreadCount > 99 ? "99+" : "\(chat.unreadCount)")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.vertical, 6)
    }
    
    private func binding(for chat: Chat) -> Binding<Chat>? {
        guard let index = viewModel.chats.firstIndex(where: { $0.id == chat.id }) else {
            return nil
        }
        return $viewModel.chats[index]
    }

}
