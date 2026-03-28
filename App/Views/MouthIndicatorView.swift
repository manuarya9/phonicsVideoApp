import SwiftUI

struct MouthIndicatorView: View {
    var body: some View {
        TimelineView(.animation) { context in
            let phase = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.15)
            let openness = 18 + abs(sin(phase * .pi * 2)) * 26

            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(red: 0.98, green: 0.93, blue: 0.85))

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.70, green: 0.14, blue: 0.20))
                    .frame(width: 90, height: openness)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                            .padding(.horizontal, 18)
                    )
                    .animation(.easeInOut(duration: 0.18), value: openness)
            }
        }
        .frame(height: 92)
        .accessibilityLabel("Mouth animation indicator")
    }
}

#Preview {
    MouthIndicatorView()
        .padding()
}

