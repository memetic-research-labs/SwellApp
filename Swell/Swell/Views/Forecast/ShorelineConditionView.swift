import SwiftUI

struct ShorelineConditionView: View {
    let beachBearing: Double
    let swellDirection: Double
    let swellHeight: Double
    let windDirection: Double
    let windScore: Double

    private let size: CGFloat = 240

    var body: some View {
        let half = size / 2

        VStack(spacing: 10) {
            ZStack {
                VStack(spacing: 0) {
                    oceanBackground
                        .frame(height: half)
                    landBackground
                        .frame(height: half)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Rectangle()
                    .fill(shorelineColor)
                    .frame(height: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .overlay(
                        Rectangle()
                            .stroke(.black.opacity(0.1), lineWidth: 0.5)
                    )

                Group {
                    Text("OCEAN")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .tracking(4)
                        .offset(y: -half + 20)

                    Text("LAND")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(4)
                        .offset(y: half - 20)
                }

                swellWedge(size: size)
                windWedge(size: size)
            }
            .frame(width: size, height: size)

            statsRow
        }
    }

    // MARK: - Backgrounds

    var oceanBackground: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.12, blue: 0.35),
                        Color(red: 0.05, green: 0.22, blue: 0.50)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    var landBackground: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.65, green: 0.55, blue: 0.35),
                        Color(red: 0.50, green: 0.40, blue: 0.24)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    // MARK: - Swell Wedge

    func swellWedge(size: CGFloat) -> some View {
        let wedgeLength = size * 0.50
        let baseW: CGFloat = 48

        return ZStack {
            WedgeShape(baseWidth: baseW, tipLength: wedgeLength)
                .fill(swellArrowColor.opacity(0.88))
            WedgeShape(baseWidth: baseW, tipLength: wedgeLength)
                .stroke(swellArrowColor, lineWidth: 2)

            Text("Swell")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .offset(y: 6)
        }
        .frame(width: baseW, height: wedgeLength)
        .offset(y: -(size - wedgeLength) / 2)
        .rotationEffect(.degrees(swellAngleRelativeToShore))
    }

    // MARK: - Wind Wedge

    func windWedge(size: CGFloat) -> some View {
        let wedgeLength = size * 0.35
        let baseW: CGFloat = 40
        let color = windArrowColor

        return ZStack {
            WedgeShape(baseWidth: baseW, tipLength: wedgeLength)
                .fill(color.opacity(0.88))
            WedgeShape(baseWidth: baseW, tipLength: wedgeLength)
                .stroke(color, lineWidth: 2)

            Text("Wind")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .offset(y: 4)
        }
        .frame(width: baseW, height: wedgeLength)
        .offset(y: -(size - wedgeLength) / 2)
        .rotationEffect(.degrees(windAngleRelativeToShore))
    }

    // MARK: - Stats

    var statsRow: some View {
        HStack(spacing: 24) {
            statChip(color: swellArrowColor, label: swellLabel)
            statChip(color: windArrowColor, label: windLabel)
        }
    }

    func statChip(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Shore-relative angles

    var swellAngleRelativeToShore: Double {
        CompassAngle.normalize(swellDirection - beachBearing)
    }

    var windAngleRelativeToShore: Double {
        CompassAngle.normalize(windDirection - beachBearing)
    }

    // MARK: - Labels

    var swellLabel: String {
        let a = swellAngleRelativeToShore
        if a < 20 || a > 340 { return "Swell: straight in" }
        if a < 55 { return "Swell: from right" }
        if a < 125 { return "Swell: angled" }
        if a > 305 { return "Swell: from left" }
        if a > 235 { return "Swell: angled" }
        if a > 160 && a < 200 { return "Swell: no swell" }
        return "Swell: angled"
    }

    var windLabel: String {
        let a = windAngleRelativeToShore
        if a > 150 && a < 210 { return "Offshore wind" }
        if a < 30 || a > 330 { return "Onshore wind" }
        if a < 80 { return "Cross-shore wind" }
        if a > 280 { return "Cross-shore wind" }
        if a < 110 { return "Side wind" }
        if a > 250 { return "Side wind" }
        return "Cross-shore wind"
    }

    var windArrowColor: Color {
        windScore > 0.6
            ? Color(red: 0.13, green: 0.77, blue: 0.33)
            : windScore > 0.3
                ? Color(red: 0.96, green: 0.62, blue: 0.13)
                : Color(red: 0.93, green: 0.27, blue: 0.27)
    }

    // MARK: - Colors

    let shorelineColor = Color(red: 0.82, green: 0.74, blue: 0.50)
    let swellArrowColor = Color(red: 0.00, green: 0.70, blue: 0.88)
}

// MARK: - Shapes

struct WedgeShape: Shape {
    let baseWidth: CGFloat
    let tipLength: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let half = baseWidth / 2
        p.move(to: CGPoint(x: rect.midX - half, y: 0))
        p.addLine(to: CGPoint(x: rect.midX + half, y: 0))
        p.addLine(to: CGPoint(x: rect.midX, y: tipLength))
        p.closeSubpath()
        return p
    }
}

// MARK: - Previews

#Preview("Offshore perfection") {
    ShorelineConditionView(beachBearing: 270, swellDirection: 275, swellHeight: 3.2, windDirection: 80, windScore: 0.85)
        .padding(40).background(Color(red: 0.96, green: 0.96, blue: 0.94))
}
#Preview("Onshore mess") {
    ShorelineConditionView(beachBearing: 270, swellDirection: 260, swellHeight: 1.2, windDirection: 280, windScore: 0.1)
        .padding(40).background(.black).preferredColorScheme(.dark)
}
#Preview("East coast") {
    ShorelineConditionView(beachBearing: 90, swellDirection: 100, swellHeight: 2.1, windDirection: 270, windScore: 0.7)
        .padding(40).background(Color(red: 0.96, green: 0.96, blue: 0.94))
}
#Preview("Cross wind") {
    ShorelineConditionView(beachBearing: 270, swellDirection: 265, swellHeight: 2.5, windDirection: 0, windScore: 0.4)
        .padding(40).background(.black).preferredColorScheme(.dark)
}