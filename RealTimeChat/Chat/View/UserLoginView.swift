//
//  UserLoginView.swift
//  RealTimeChat
//
//  Created by Sandeep on 25/04/25.
//

import SwiftUI

struct UserLoginView: View {
    @ObservedObject var viewModel: ChatViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select a user to login")
                    .font(.headline)

                ForEach(viewModel.dummyUsers) { user in
                    Button(action: {
                        viewModel.login(as: user)
                    }) {
                        Text("Continue as \(user.name)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .navigationTitle("Login")
        }
    }
}
