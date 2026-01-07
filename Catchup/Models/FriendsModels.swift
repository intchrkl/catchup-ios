//
//  FriendsModels.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

// Model/FriendsModels.swift
import Foundation

struct FriendLite: Identifiable {
    var id: String { friendUid }
    let friendUid: String
    let friendName: String
    let friendUsername: String
    let since: Date
    let sourcePairId: String
    let streaks: Int
}

struct FriendRequestDTO: Identifiable {
    var id: String { pairId }
    let pairId: String
    let userA: String
    let userB: String
    let status: String        // "pending" | "accepted" | "declined"
    let requestedBy: String
    let createdAt: Date
}
