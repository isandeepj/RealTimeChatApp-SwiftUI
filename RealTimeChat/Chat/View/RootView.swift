//
//  RootView.swift
//  RealTimeChat
//
//  Created by Sandeep on 25/04/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if viewModel.currentUser == nil {
                UserLoginView(viewModel: viewModel)
            } else {
                ChatListView(viewModel: viewModel)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                viewModel.reconnectSocketIfNeeded()
            case .background:
                print("App in background")
            case .inactive:
                print("App is inactive")
            @unknown default:
                break
            }
        }
    }
}
