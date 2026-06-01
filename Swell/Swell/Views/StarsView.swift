import SwiftUI

struct StarsView: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .foregroundStyle(starsColor)
            }
        }
    }

    var starsColor: Color {
        switch rating {
        case 4...5: return .green
        case 3: return .yellow
        default: return .red
        }
    }
}