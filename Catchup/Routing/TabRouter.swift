//
//  TabRouter.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import SwiftUI
import Combine

enum AppTab: Int { case home = 0, outbox = 1, inbox = 2, profile = 3 }

final class TabRouter: ObservableObject {
    @Published var selected: AppTab = .home
}
