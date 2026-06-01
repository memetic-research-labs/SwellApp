import Foundation
import UserNotifications

protocol NotificationScheduling {
    func requestAuthorization() async throws -> Bool
    func scheduleIfGood(_ scores: [HourlySurfScore], beachName: String, minimumStars: Int) async
    func cancelPending(for beachName: String) async
}

actor NotificationService: NotificationScheduling {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleIfGood(_ scores: [HourlySurfScore], beachName: String, minimumStars: Int) async {
        await cancelPending(for: beachName)

        let goodWindows = extractWindows(from: scores, minimumStars: minimumStars)

        for (index, window) in goodWindows.prefix(3).enumerated() {
            let content = UNMutableNotificationContent()
            content.title = window.count > 1
                ? "\(beachName) firing soon"
                : "\(beachName) is on"

            let bestScore = window.max(by: { $0.starRating < $1.starRating })!

            content.body = "\(starText(bestScore.starRating)) \(Int(bestScore.swellHeight * 3.28084))ft" +
                ", \(windLabel(bestScore))" +
                ". \(formatWindow(window))"

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let identifier = "swell-\(beachName)-\(index)"

            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    func cancelPending(for beachName: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [
            "swell-\(beachName)-0",
            "swell-\(beachName)-1",
            "swell-\(beachName)-2"
        ])
    }

    private func extractWindows(from scores: [HourlySurfScore], minimumStars: Int) -> [[HourlySurfScore]] {
        var windows: [[HourlySurfScore]] = []
        var current: [HourlySurfScore] = []

        for score in scores {
            if score.starRating >= minimumStars {
                current.append(score)
            } else if !current.isEmpty {
                windows.append(current)
                current = []
            }
        }
        if !current.isEmpty {
            windows.append(current)
        }
        return windows
    }

    private func formatWindow(_ window: [HourlySurfScore]) -> String {
        guard let first = window.first?.time, let last = window.last?.time else { return "" }
        let firstTime = dateString(from: first)
        let lastTime = timeString(from: last)
        return "\(firstTime)-\(lastTime)"
    }

    private func windLabel(_ score: HourlySurfScore) -> String {
        if score.windScore > 0.6 { return "offshore" }
        if score.windScore > 0.3 { return "cross-shore" }
        return "onshore"
    }

    private func starText(_ stars: Int) -> String {
        switch stars {
        case 5: return "Epic"
        case 4: return "Good"
        default: return "Surfable"
        }
    }

    private func dateString(from iso: String) -> String {
        iso.components(separatedBy: "T").first ?? iso
    }

    private func timeString(from iso: String) -> String {
        let parts = iso.components(separatedBy: "T")
        guard parts.count == 2 else { return "" }
        return String(parts[1].prefix(5))
    }
}