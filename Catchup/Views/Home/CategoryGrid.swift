// View/Home/CategoryGrid.swift
import SwiftUI

struct CategoryGrid: View {
    var onSelect: (QuestionCategory) -> Void

    private let items: [CategoryItem] = [
        .init(category: .selfReflection,
              title: "Self Reflection",
              subtitle: "Think about how you’ve grown!",
              color: Color(asset: "CU.Orange", fallback: .orange),
              icon: "figure.mind.and.body"),
        .init(category: .memories,
              title: "Memories",
              subtitle: "Talk about your favorite times!",
              color: Color(asset: "CU.indigo", fallback: .indigo),
              icon: "sparkles"),
        .init(category: .relationships,
              title: "Relationships",
              subtitle: "How are your loved ones?",
              color: Color(asset: "CU.Pink", fallback: .pink),
              icon: "person.2.fill"),
        .init(category: .wouldYouRather,
              title: "Would You Rather",
              subtitle: "Use your imagination!",
              color: Color(asset: "CU.Green", fallback: .green),
              icon: "die.face.5.fill"),
        .init(category: .goals,
              title: "Goals",
              subtitle: "Share you achievements!",
              color: Color(asset: "CU.Red", fallback: .red),
              icon: "target"),
        .init(category: .gratitude,
              title: "Gratitude",
              subtitle: "What are you thankful for?",
              color: Color(asset: "CU.Yellow", fallback: .yellow),
              icon: "hands.sparkles.fill"),
    ]

    private let columns = [GridItem(.flexible(), spacing: 16),
                           GridItem(.flexible(), spacing: 16)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(items) { it in
                CategoryCard(item: it) { onSelect(it.category) }
            }

            // Fillers to keep last row balanced
            let fillers = (2 - (items.count % 2)) % 2
            if fillers > 0 {
                ForEach(0..<fillers, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(asset: "CU.Yellow", fallback: .yellow).opacity(0.85))
                        .frame(height: 130)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.7))
                        )
                }
            }
        }
    }
}

struct CategoryItem: Identifiable {
    let id = UUID()
    let category: QuestionCategory
    let title: String
    let subtitle: String
    let color: Color
    let icon: String
}

struct CategoryCard: View {
    let item: CategoryItem
    var onTap: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            // tiny haptic (optional—remove if you dislike logs in Simulator)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                pressed = true
            }
            // defer reset so the scale animates back
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    pressed = false
                }
            }
            onTap()
        }) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(item.color)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Spacer()
                        Image(systemName: item.icon)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.9))
                            .accessibilityHidden(true)
                    }
                    Spacer()
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }
                .padding(16)
                .background(
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.black.opacity(0.15))
                            .frame(height: 40)
                    }
                )
            }
            .frame(height: 130)
            .shadow(color: .black.opacity(0.08), radius: 8, y: 6)
            .scaleEffect(pressed ? 0.97 : 1.0)
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(item.title))
        .accessibilityHint(Text("Open \(item.title) questions"))
    }
}

// MARK: - Safe Color helper (avoids crashes if asset not present)
private extension Color {
    init(asset name: String, fallback: Color) {
        self = Color(name, bundle: .main)
    }
}
