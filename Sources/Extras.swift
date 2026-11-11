import SwiftUI
import UIKit
import AudioToolbox
import GameKit

// MARK: - Tipuri de joc

enum GameKind: Hashable {
    /// Trei simboluri identice = câștig.
    case matchThree
    /// Dacă numărul tău norocos apare printre cele 6 numere = câștig.
    case luckyNumber
}

// MARK: - Sunet și vibrație (respectă setările jucătorului)

enum Feedback {
    private static func flag(_ key: String) -> Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? true
    }
    static var soundOn: Bool { flag("soundOn") }
    static var hapticsOn: Bool { flag("hapticsOn") }

    // Sunete de sistem iOS, ca să nu fie nevoie de fișiere audio.
    static func win() { if soundOn { AudioServicesPlaySystemSound(1025) } }
    static func lose() { if soundOn { AudioServicesPlaySystemSound(1024) } }
}

// MARK: - Confetti

struct ConfettiView: View {
    private struct Piece {
        let x = CGFloat.random(in: 0...1)
        let delay = Double.random(in: 0...0.6)
        let speed = CGFloat.random(in: 0.45...0.9)      // ecrane pe secundă
        let wobble = Double.random(in: 2...6)
        let spin = Double.random(in: -6...6)
        let color = [Color.red, .yellow, .green, .blue, .pink, .orange, .purple].randomElement() ?? .yellow
    }

    @State private var start = Date()
    @State private var pieces: [Piece] = (0..<90).map { _ in Piece() }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(start)
                for piece in pieces {
                    let t = elapsed - piece.delay
                    guard t > 0 else { continue }
                    let y = -20 + CGFloat(t) * piece.speed * size.height
                    guard y < size.height + 20 else { continue }
                    let x = piece.x * size.width + CGFloat(sin(t * piece.wobble)) * 18

                    var layer = context
                    layer.translateBy(x: x, y: y)
                    layer.rotate(by: .radians(t * piece.spin))
                    layer.fill(Path(CGRect(x: -4, y: -7, width: 8, height: 14)), with: .color(piece.color))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - Degetul care arată cum se răzuiește (primul loz)

struct HintFinger: View {
    @State private var moved = false

    var body: some View {
        Text("👆")
            .font(.system(size: 56))
            .offset(x: moved ? 70 : -70, y: 30)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { moved = true }
            }
            .allowsHitTesting(false)
    }
}

// MARK: - Statistici (ținute pe telefon)

enum Stats {
    private static let store = UserDefaults.standard

    static func recordTicket(_ ticket: Ticket) {
        store.set(store.integer(forKey: "statTickets") + 1, forKey: "statTickets")
        store.set(store.integer(forKey: "statTotalWon") + ticket.prize, forKey: "statTotalWon")
        if ticket.prize > store.integer(forKey: "statBiggestWin") {
            store.set(ticket.prize, forKey: "statBiggestWin")
        }
        if ticket.outcome == .jackpot {
            store.set(store.integer(forKey: "statJackpots") + 1, forKey: "statJackpots")
        }
        Achievements.sync()
    }

    static func recordStreak(_ day: Int) {
        if day > store.integer(forKey: "statBestStreak") {
            store.set(day, forKey: "statBestStreak")
        }
        Achievements.sync()
    }
}

// MARK: - Realizări

struct Achievement: Identifiable {
    /// Trebuie să fie identic cu ID-ul realizării din App Store Connect.
    let id: String
    let title: String
    let detail: String
    let isDone: () -> Bool
}

enum Achievements {
    private static let store = UserDefaults.standard

    static let all: [Achievement] = [
        Achievement(id: "lozuri.primul_jackpot", title: "👑 Primul jackpot", detail: "Câștigă un jackpot") {
            store.integer(forKey: "statJackpots") >= 1
        },
        Achievement(id: "lozuri.100_lozuri", title: "🎟️ Răzuitor de cursă lungă", detail: "Răzuiește 100 de lozuri") {
            store.integer(forKey: "statTickets") >= 100
        },
        Achievement(id: "lozuri.serie_7", title: "🔥 Săptămâna perfectă", detail: "Ia bonusul 7 zile la rând") {
            store.integer(forKey: "statBestStreak") >= 7
        },
        Achievement(id: "lozuri.toate_mesajele", title: "💬 Înțeleptul", detail: "Descoperă toate mesajele") {
            seenMessageIndices(store.string(forKey: "seenMessages") ?? "").count >= TicketScreen.losingMessages.count
        },
    ]

    /// Trimite în Game Center realizările îndeplinite, fiecare o singură dată.
    static func sync() {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        for achievement in all where achievement.isDone() {
            let key = "reported." + achievement.id
            guard !store.bool(forKey: key) else { continue }
            store.set(true, forKey: key)
            let report = GKAchievement(identifier: achievement.id)
            report.percentComplete = 100
            report.showsCompletionBanner = true
            GKAchievement.report([report]) { _ in }
        }
    }
}

// MARK: - Ecranul de statistici

struct StatsScreen: View {
    @AppStorage("statTickets") private var tickets = 0
    @AppStorage("statTotalWon") private var totalWon = 0
    @AppStorage("statBiggestWin") private var biggestWin = 0
    @AppStorage("statJackpots") private var jackpots = 0
    @AppStorage("statBestStreak") private var bestStreak = 0

    var body: some View {
        List {
            Section("Statistici") {
                LabeledContent("Lozuri răzuite", value: "\(tickets)")
                LabeledContent("Monede câștigate în total", value: "\(totalWon)")
                LabeledContent("Cel mai mare câștig", value: "\(biggestWin)")
                LabeledContent("Jackpoturi", value: "\(jackpots)")
                LabeledContent("Cea mai lungă serie", value: "\(bestStreak) zile")
            }

            Section("Realizări") {
                ForEach(Achievements.all) { achievement in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(achievement.title).font(.headline)
                            Text(achievement.detail).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(achievement.isDone() ? "✅" : "🔒")
                    }
                }
            }
        }
        .navigationTitle("Statistici")
    }
}

// MARK: - Ecranul de setări

struct SettingsScreen: View {
    @AppStorage("soundOn") private var soundOn = true
    @AppStorage("hapticsOn") private var hapticsOn = true
    @AppStorage("tapToReveal") private var tapToReveal = false

    var body: some View {
        Form {
            Section {
                Toggle("Sunet", isOn: $soundOn)
                Toggle("Vibrație", isOn: $hapticsOn)
            }
            Section {
                Toggle("Atinge ca să dezvălui", isOn: $tapToReveal)
            } footer: {
                Text("Lozul se dezvăluie la o singură atingere, fără răzuit cu degetul.")
            }
        }
        .navigationTitle("Setări")
    }
}
