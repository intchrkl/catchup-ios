//
//  StreakService.swift
//  Catchup
//
//  Created by Nick Jitjang on 11/19/25.
//

import Foundation
import FirebaseFirestore

final class StreakService {
    static let shared = StreakService()
    private let db: Firestore

    // Keep default behavior for app, allow DI for tests
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - App-wide streak

    /// Bump/reset app-wide streak when user answers today.
    func updateUserStreak(uid: String, timezoneId: String) async throws {
        let todayKey = StreakDate.dayKey(tzId: timezoneId)
        let ref = db.collection("users").document(uid)

        try await db.runTransaction { tran, errorPointer in
            do {
                let snap = try tran.getDocument(ref)
                var data = snap.data() ?? [:]
                var stats = data["stats"] as? [String: Any] ?? [:]

                let oldStreak = stats["streakDays"] as? Int ?? 0
                let lastDateKey = stats["lastStreakDate"] as? String

                let (newStreak, newLastDate) = StreakDate.updatedStreak(
                    oldStreak: oldStreak,
                    lastDateKey: lastDateKey,
                    todayKey: todayKey,
                    tzId: timezoneId
                )

                stats["streakDays"] = newStreak
                stats["lastStreakDate"] = newLastDate
                data["stats"] = stats

                tran.setData(data, forDocument: ref, merge: true)
                return nil
            } catch {
                if let errorPointer = errorPointer {
                    errorPointer.pointee = error as NSError
                }
                return nil
            }
        }
    }

    // MARK: - Friend streaks

    /// Bump/reset the streak for every accepted friendship that involves this user.
    /// "goes up by 1 if either friend answers that day"
    func updateFriendStreaksForUser(
        uid: String,
        recipients: [String],
        timezoneId: String
    ) async throws {
        guard !recipients.isEmpty else { return }

        let todayKey = StreakDate.dayKey(tzId: timezoneId)

        for friendUid in recipients {
            // Compute the stable pairId used in `friendships/{pairId}`
            let pairId: String
            if uid < friendUid {
                pairId = "\(uid)__\(friendUid)"
            } else {
                pairId = "\(friendUid)__\(uid)"
            }

            let pairRef = db.collection("friendships").document(pairId)

            try await db.runTransaction { tran, errorPointer in
                do {
                    let pairSnap = try tran.getDocument(pairRef)
                    guard var pairData = pairSnap.data() else {
                        // No friendship doc? Nothing to update.
                        return nil
                    }

                    // Only update if this friendship is accepted
                    let status = pairData["status"] as? String ?? "pending"
                    if status != "accepted" {
                        return nil
                    }

                    let oldStreak   = pairData["streak"] as? Int ?? 0
                    let lastDateKey = pairData["lastStreakDate"] as? String

                    let (newStreak, newLastDate) = StreakDate.updatedStreak(
                        oldStreak: oldStreak,
                        lastDateKey: lastDateKey,
                        todayKey: todayKey,
                        tzId: timezoneId
                    )

                    pairData["streak"] = newStreak
                    pairData["lastStreakDate"] = newLastDate
                    tran.setData(pairData, forDocument: pairRef, merge: true)

                    // Mirror streak into both users' subcollections:
                    let aRef = self.db
                        .collection("users").document(uid)
                        .collection("friends").document(friendUid)

                    let bRef = self.db
                        .collection("users").document(friendUid)
                        .collection("friends").document(uid)

                    let update: [String: Any] = [
                        "streaks": newStreak,
                        "lastStreakDate": newLastDate
                    ]

                    // Use setData(merge:) so we don't crash if the friend doc somehow doesn't exist yet.
                    tran.setData(update, forDocument: aRef, merge: true)
                    tran.setData(update, forDocument: bRef, merge: true)

                    return nil
                } catch {
                    if let errorPointer = errorPointer {
                        errorPointer.pointee = error as NSError
                    }
                    return nil
                }
            }
        }
    }
}

