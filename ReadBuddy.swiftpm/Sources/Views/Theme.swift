import SwiftUI

enum ReadBuddyTheme {
    static let background = Color(red: 0.975, green: 0.972, blue: 0.985)
    static let card = Color.white
    static let ink = Color(red: 0.08, green: 0.08, blue: 0.09)
    static let secondary = Color(red: 0.42, green: 0.42, blue: 0.46)
    static let glow = Color(red: 0.48, green: 0.78, blue: 0.78)
}

struct ReadBuddyCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .background(ReadBuddyTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            }
    }
}

struct BrandHeader: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "book.closed.fill")
            Text("ReadBuddy")
                .font(.headline.weight(.bold))
            Spacer()
            Image(systemName: "gearshape")
                .foregroundStyle(ReadBuddyTheme.secondary)
        }
    }
}
