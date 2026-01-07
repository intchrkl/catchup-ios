//
//  RootView.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionController
    @StateObject private var router = TabRouter()

    var body: some View {
        Group {
            if session.user == nil {
                AuthView()
            } else {
                ZStack(alignment: .bottom) {
                    Group {
                        switch router.selected {
                        case .home:    HomeView()
                        case .outbox:  SentAnswersView()        // placeholder
                        case .inbox:   ReceivedAnswersView()       // placeholder
                        case .profile: ProfileView()
                        }
                    }
                    .transition(.opacity)

                    FloatingTabBar()
                        .environmentObject(router)
                        .padding(.bottom, 16)
                }
            }
        }
        .environmentObject(router)   // so children can read the router if needed
    }
}

// simple stub so it compiles
struct InboxPlaceholderView: View {
    var body: some View { Text("Inbox (placeholder)").padding() }
}
