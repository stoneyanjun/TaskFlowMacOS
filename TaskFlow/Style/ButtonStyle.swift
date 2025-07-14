
import SwiftUI
import SwiftData

struct LargeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 24, weight: .semibold)) // 1.5× typical 16pt font
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

struct MediumLargeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .medium)) // ≈ 1.2× default
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}
