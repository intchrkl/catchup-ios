import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionController
    @EnvironmentObject var auth: AuthController

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    
                    NavigationLink {
                        AccountSettingsView()
                    } label: {
                        ProfileHeaderCard(
                            name: session.user?.displayName ?? "John Pork",
                            username: session.user?.username ?? "john_pork",
                            joined: joinedString(from: session.user?.createdAt),
                            photoURL: session.user?.photoURL,          // ← add
                            streakDays: session.user?.stats.streakDays ?? 0
                        )
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 14) {
                        // NavigationLink row for Account Settings
                        NavigationLink {
                            AccountSettingsView()
                        } label: {
                            ProfileRowVisual(title: "Account Settings")
                        }
                        .buttonStyle(.plain)

                        // NavigationLink uses a NON-button row
                        NavigationLink {
                            MyFriendsView()
                        } label: {
                            ProfileRowVisual(title: "My Friends")
                        }
                        .buttonStyle(.plain)

                        NavigationLink { AppSettingsView() } label: {
                            ProfileRowVisual(title: "App Settings")
                        }
                        .buttonStyle(.plain)

                        ProfileRowButton(title: "Notifications") { /* TODO */ }

                        Button(action: { auth.signOut() }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out").font(.headline)
                                Spacer()
                            }
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(RoundedRectangle(cornerRadius: 18).fill(Color.red.opacity(0.85)))
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 80)
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func joinedString(from date: Date?) -> String {
        guard let date else { return "Joined recently" }
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return "Joined in \(f.string(from: date))"
    }
}

// MARK: - Components

private struct ProfileHeaderCard: View {
    let name: String
    let username: String
    let joined: String
    var photoURL: String? = nil          // add
    var avatarKey: String? = nil         // add
    let streakDays: Int


    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22).fill(Color("CU.Orange"))

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 14) {
                    AvatarView(photoURL: photoURL, avatarKey: avatarKey, size: 56)  // ← use it
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name).font(.title3.weight(.semibold)).foregroundStyle(.white)
                        Text("@\(username)").font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.95))
                    }
                    Spacer()
                    VStack(spacing: 2) {
                            Text("\(streakDays)")
                                .font(.title2.bold())
                                .foregroundStyle(.white)

                            Text("Streak 🔥")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.22))
                        )
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                Spacer()
            }

            HStack(spacing: 12) {
                Spacer().frame(width: 18)
                VStack(alignment: .leading, spacing: 4) {
                    Text("@\(username)").font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    Text(joined).font(.caption).foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
            }
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 22).fill(Color("CU.Brown")).frame(height: 70)
            )
        }
        .frame(height: 150)
        .padding(.horizontal, 20)
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
    }
}

// Reusable avatar
struct AvatarView: View {
    let photoURL: String?
    let avatarKey: String?
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(.white.opacity(0.25))
            if let s = photoURL, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: ProgressView()
                    case .success(let img): img.resizable().scaledToFill()
                    case .failure: assetOrSymbol
                    @unknown default: assetOrSymbol
                    }
                }
                .clipShape(Circle())
            } else {
                assetOrSymbol
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder private var assetOrSymbol: some View {
        if let key = avatarKey, !key.isEmpty {
            Image(key).resizable().scaledToFill().clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable().scaledToFit()
                .foregroundStyle(.white)
        }
    }
}

// Visual row (no button)
private struct ProfileRowVisual: View {
    let title: String
    var body: some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .frame(height: 60)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.gray.opacity(0.6)))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

// Button row (for actions)
private struct ProfileRowButton: View {
    let title: String; var action: () -> Void
    var body: some View {
        Button(action: action) {
            ProfileRowVisual(title: title)
        }
        .buttonStyle(.plain)
    }
}
