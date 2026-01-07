//
//  HeroPager.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//
import SwiftUI

private func heroColorForCategory(_ category: String?) -> Color {
    switch category?.lowercased() {
    case let c? where c.contains("self reflection"):
        return Color("CU.Orange")
    case let c? where c.contains("memories"):
        return Color("CU.indigo")
    case let c? where c.contains("relationships"):
        return Color("CU.Pink")
    case let c? where c.contains("would you rather"):
        return Color("CU.Green")
    case let c? where c.contains("goals"):
        return Color("CU.Red")
    case let c? where c.contains("gratitude"):
        return Color("CU.Yellow")
    default:
        return Color.gray  // fallback if missing
    }
}


struct HeroPager: View {
    let answers: [AnswerCardVM]
    @State private var index: Int = 0
    
    var onOpenInbox: (() -> Void)? = nil

    var body: some View {
        ZStack {
            if answers.isEmpty {
                HeroPlaceholderCard()
            } else {
                VStack(spacing: 12) {
                    TabView(selection: $index) {
                        ForEach(Array(answers.enumerated()), id: \.offset) { i, vm in
                            HeroAnswerCard(vm: vm).tag(i)
                        }
                    }
                    .frame(height: 220)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
        }
        // Make the whole hero area tappable to open the reels inbox
        .contentShape(Rectangle())
        .onTapGesture { onOpenInbox?() }
    }
}

struct HeroAnswerCard: View {
    let vm: AnswerCardVM

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // background
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(heroColorForCategory(vm.category))

            // prompt text
            VStack(alignment: .leading, spacing: 0) {
                Text(vm.promptText)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(20)
                Spacer()
            }

            // bottom band with avatar + author + heart
            HStack(spacing: 12) {
                AvatarView(photoURL: vm.authorPhotoURL, avatarKey: nil, size: 38)

                Text("\(vm.authorName) answered!")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button(action: { /* like */ }) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Circle().fill(.white.opacity(0.25)))
                }
                .buttonStyle(.plain)
            }

            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.black.opacity(0.20))
                    .frame(height: 64)
                    .offset(y: 0),
                alignment: .bottom
            )
        }
        .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 220)
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
    }
}

private struct HeroPlaceholderCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.gray.opacity(0.75))

            VStack(alignment: .leading, spacing: 8) {
                Text("No answers yet")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    

                Text("When friends share answers, they’ll appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 60)
            }
            .padding(20)

            HStack(spacing: 12) {
                Image(systemName: "tray.and.arrow.down.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Circle().fill(.white.opacity(0.25)))

                Text("Tap to view inbox")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.black.opacity(0.20))
                    .frame(height: 64)
                    .offset(y: 0),
                alignment: .bottom
            )
        }
        .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 220)
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
    }
}
