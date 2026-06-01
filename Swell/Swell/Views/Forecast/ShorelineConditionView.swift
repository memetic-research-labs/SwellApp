import SwiftUI

struct ShorelineConditionView: View {
    let beachBearing: Double
    let swellDirection: Double
    let swellHeight: Double
    let windDirection: Double
    let windScore: Double

    private let size: CGFloat = 240

    var body: some View {
        let oceanHeight = size * 0.85
        let landHeight = size * 0.15
        let shorelineY = oceanHeight - size / 2

        VStack(spacing: 10) {
            ZStack {
                VStack(spacing: 0) {
                    oceanBackground
                        .frame(height: oceanHeight)
                    landBackground
                        .frame(height: landHeight)
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
                    .offset(y: shorelineY)

                Group {
                    Text("OCEAN")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .tracking(4)
                        .offset(y: -size / 2 + 18)

                    Text("LAND")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(4)
                        .offset(y: size / 2 - 20)
                }

                swellArrow(size: size)
                windArrow(size: size)
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

    // MARK: - Swell Arrow

    func swellArrow(size: CGFloat) -> some View {
        let arrowLength = size * 0.52
        let shaftW: CGFloat = 16
        let headW: CGFloat = 36
        let headL: CGFloat = 14
        let color = swellColor

        return ZStack {
            ThickArrowShape(
                shaftWidth: shaftW,
                headWidth: headW,
                shaftLength: arrowLength - headL,
                headLength: headL,
                totalLength: arrowLength
            )
            .fill(color.opacity(0.90))
            .overlay(
                ThickArrowShape(
                    shaftWidth: shaftW,
                    headWidth: headW,
                    shaftLength: arrowLength - headL,
                    headLength: headL,
                    totalLength: arrowLength
                )
                .stroke(.white.opacity(0.3), lineWidth: 1)
            )

            Text("Swell")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(-swellAngleRelativeToShore))
                .offset(y: -arrowLength / 2 + 14)
        }
        .frame(width: headW, height: arrowLength)
        .offset(y: -(size - arrowLength) / 2)
        .rotationEffect(.degrees(swellAngleRelativeToShore))
    }

    // MARK: - Wind Arrow

    func windArrow(size: CGFloat) -> some View {
        let arrowLength = size * 0.38
        let shaftW: CGFloat = 12
        let headW: CGFloat = 30
        let headL: CGFloat = 12
        let color = windColor

        return ZStack {
            ThickArrowShape(
                shaftWidth: shaftW,
                headWidth: headW,
                shaftLength: arrowLength - headL,
                headLength: headL,
                totalLength: arrowLength
            )
            .fill(color.opacity(0.90))
            .overlay(
                ThickArrowShape(
                    shaftWidth: shaftW,
                    headWidth: headW,
                    shaftLength: arrowLength - headL,
                    headLength: headL,
                    totalLength: arrowLength
                )
                .stroke(.white.opacity(0.3), lineWidth: 1)
            )

            Text("Wind")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(-windAngleRelativeToShore))
                .offset(y: -arrowLength / 2 + 12)
        }
        .frame(width: headW, height: arrowLength)
        .offset(y: -(size - arrowLength) / 2)
        .rotationEffect(.degrees(windAngleRelativeToShore))
    }

    // MARK: - Stats

    var statsRow: some View {
        HStack(spacing: 24) {
            statChip(color: windColor, label: windLabel)
            statChip(color: swellColor, label: swellLabel)
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

    // MARK: - Colors

    let shorelineColor = Color(red: 0.82, green: 0.74, blue: 0.50)
    let swellColor = Color.blue
    let windColor = Color.purple
}

// MARK: - Shapes

struct ThickArrowShape: Shape {
    let shaftWidth: CGFloat
    let headWidth: CGFloat
    let shaftLength: CGFloat
    let headLength: CGFloat
    let totalLength: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let midX = rect.midX
        let shaftHalf = shaftWidth / 2
        let headHalf = headWidth / 2
        let headStartY = shaftLength

        p.move(to: CGPoint(x: midX - shaftHalf, y: 0))
        p.addLine(to: CGPoint(x: midX + shaftHalf, y: 0))
        p.addLine(to: CGPoint(x: midX + shaftHalf, y: headStartY))
        p.addLine(to: CGPoint(x: midX + headHalf, y: headStartY))
        p.addLine(to: CGPoint(x: midX, y: totalLength))
        p.addLine(to: CGPoint(x: midX - headHalf, y: headStartY))
        p.addLine(to: CGPoint(x: midX - shaftHalf, y: headStartY))
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