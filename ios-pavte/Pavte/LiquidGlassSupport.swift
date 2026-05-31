import SwiftUI

struct PavteBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.07, blue: 0.13), Color(red: 0.02, green: 0.15, blue: 0.17), Color(red: 0.08, green: 0.05, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color.cyan.opacity(0.28))
                .blur(radius: 70)
                .offset(x: -140, y: -260)
            Circle()
                .fill(Color.teal.opacity(0.22))
                .blur(radius: 90)
                .offset(x: 160, y: 120)
            Circle()
                .fill(Color.blue.opacity(0.16))
                .blur(radius: 80)
                .offset(x: -40, y: 320)
        }
    }
}

struct GlassSurface<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: Content

    init(cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(.white.opacity(0.22), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    func pavteGlassCard(cornerRadius: CGFloat = 24) -> some View {
        GlassSurface(cornerRadius: cornerRadius) { self }
    }
}
