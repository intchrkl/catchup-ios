//
//  FriendRowVM.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

// Model/FriendRowVM.swift
import Foundation

struct FriendRowVM: Identifiable {
    var id: String { uid }
    let uid: String
    let displayName: String
    let username: String
    let photoURL: String?
    let since: Date
    let streaks: Int        // new
}

