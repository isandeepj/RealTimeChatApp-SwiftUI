//
//  CreateChatView.swift
//  RealTimeChat
//
//  Created by Sandeep on 25/04/25.
//

import SwiftUI

struct CreateChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.dummyUsers.filter { $0.id != viewModel.currentUser?.id }) { user in
                    Button(action: {
                        viewModel.startNewChat(with: user)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Chat with \(user.name)")
                    }
                }
            }
            .navigationTitle("New Conversation")
        }
    }
}
