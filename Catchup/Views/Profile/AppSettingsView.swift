//
//  AppSettingsView.swift
//  Catchup
//
//  Created by Nick Jitjang on 11/19/25.
//

import SwiftUI

struct AppSettingsView: View {
    @EnvironmentObject var session: SessionController
    @StateObject private var vm = AppSettingsController()
    @State private var pending: [UNNotificationRequest] = []
    @State private var delivered: [UNNotification] = []


    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Enable Push Notifications", isOn: $vm.pushEnabled)
                    .onChange(of: vm.pushEnabled) { newValue in
                        // Immediately reflect in scheduled local notifs (no need to wait for save)
                        LocalPushCoordinator.shared.ensureDailySchedules(
                            pushEnabled: newValue,
                            inAppNotification: vm.inAppNotification
                        )
                    }

                Toggle("In-App Notifications", isOn: $vm.inAppNotification)
                    .onChange(of: vm.inAppNotification) { newValue in
                        LocalPushCoordinator.shared.ensureDailySchedules(
                            pushEnabled: vm.pushEnabled,
                            inAppNotification: newValue
                        )
                    }

                // (Optional) Show today’s cancel button for testing UX
                Button("I answered today → Cancel tonight’s reminder") {
                    LocalPushCoordinator.shared.cancelTonightsStreakReminder()
                }
                .buttonStyle(.bordered)
            }

            Section("Timezone") {
                HStack {
                    Text("Device Timezone")
                    Spacer()
                    Text(vm.timezone).foregroundStyle(.secondary)
                }
            }

            if let err = vm.errorMessage {
                Section { Text(err).foregroundColor(.red) }
            }

            Section {
                Button {
                    Task { await vm.saveAndApply() }
                } label: {
                    if vm.isSaving { ProgressView() }
                    else { Text("Save Settings").frame(maxWidth: .infinity) }
                }
                .disabled(vm.isSaving)
            }
            
            Button("Test local notif in 5s") {
                let trig = timeIntervalTrigger(seconds: 5)
                let n = LocalNotification(
                    id: "test-\(UUID().uuidString)",
                    title: "Test",
                    body: "If you see this, local notifications work ✅",
                    userInfo: nil,
                    trigger: trig
                )
                NotificationService.shared.schedule(n)
            }

        }
        .navigationTitle("App Settings")
        .onAppear {
            vm.load(from: session.user)   // instant load from session cache
        }
        
        List {
                    Section("Pending (\(pending.count))") {
                        ForEach(pending, id: \.identifier) { req in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(req.content.title)
                                    .font(.headline)
                                Text(req.identifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if let trig = req.trigger as? UNCalendarNotificationTrigger {
                                    Text("Calendar trigger: \(trig.dateComponents)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                } else if let trig = req.trigger as? UNTimeIntervalNotificationTrigger {
                                    Text("Timer: \(trig.timeInterval)s, repeats=\(trig.repeats)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Section("Delivered (\(delivered.count))") {
                        ForEach(delivered, id: \.request.identifier) { notif in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notif.request.content.title)
                                    .font(.headline)
                                Text(notif.request.identifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("Notif Debug")
                .onAppear {
                    reload()
                }
                .refreshable {
                    reload()
                }
            }

            private func reload() {
                let center = UNUserNotificationCenter.current()
                center.getPendingNotificationRequests { pendingReqs in
                    DispatchQueue.main.async {
                        self.pending = pendingReqs
                    }
                }
                center.getDeliveredNotifications { deliveredNotifs in
                    DispatchQueue.main.async {
                        self.delivered = deliveredNotifs
                    }
                }
            }
        }
