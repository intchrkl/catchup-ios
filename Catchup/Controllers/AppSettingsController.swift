//
//  AppSettingsController.swift
//  Catchup
//
//  Created by Nick Jitjang on 11/19/25.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
final class AppSettingsController: ObservableObject {
    @Published var pushEnabled = true
    @Published var inAppNotification = true
    @Published var timezone = TimeZone.current.identifier

    @Published var isSaving = false
    @Published var errorMessage: String?

    private let usersRepo = UsersRepository()
    private var uid: String { Auth.auth().currentUser?.uid ?? "" }

    func load(from user: User?) {
        // initialize from current session first (instant UI), fall back to fetch if needed
        if let u = user {
            pushEnabled        = u.settings.pushEnabled
            inAppNotification  = u.settings.inAppNotification
            timezone           = u.settings.timezone
        }
    }

    func saveAndApply() async {
        guard !uid.isEmpty else { return }
        isSaving = true; defer { isSaving = false }
        errorMessage = nil

        do {
            try await usersRepo.updateSettings(uid: uid,
                                               pushEnabled: pushEnabled,
                                               inAppNotification: inAppNotification,
                                               timezone: timezone)

            // (Optional) belt-and-suspenders: ensure schedules reflect new toggles right away
            LocalPushCoordinator.shared.ensureDailySchedules(
                pushEnabled: pushEnabled,
                inAppNotification: inAppNotification
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
