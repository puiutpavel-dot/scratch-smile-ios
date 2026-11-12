import SwiftUI
import UIKit
import UserNotifications
import GameKit
import MessageUI

/// Adresa la care îți scriu jucătorii. Schimb-o cu adresa ta de contact.
let supportEmail = "contact@exemplu.ro"

/// Mesajele descoperite sunt ținute ca listă de indici, de forma "0,3,7".
func seenMessageIndices(_ stored: String) -> Set<Int> {
    Set(stored.split(separator: ",").compactMap { Int($0) })
}

/// Numele aplicației, afișat pe imaginile trimise. Schimbă-l cu numele tău final.
let appName = "Scratch & Smile"

/// Textul în limba telefonului (vezi tools/l10n.py). Valorile se trec ca text: L("win", "\(prize)").
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, comment: "")
    return args.isEmpty ? format : String(format: format, locale: Locale.current, arguments: args)
}

// MARK: - Logica de câștig (rezultatul se decide ÎNAINTE de răzuit)

enum Outcome: CaseIterable {
    case lose, moneyBack, medium, jackpot

    /// Extragere ponderată; `weights` e în ordinea din `allCases`.
    static func random(weights: [Int]) -> Outcome {
        var roll = Int.random(in: 0..<weights.reduce(0, +))
        for (outcome, weight) in zip(allCases, weights) {
            if roll < weight { return outcome }
            roll -= weight
        }
        return .lose
    }
}

struct Ticket {
    let price: Int
    let outcome: Outcome
    let prize: Int
    let symbols: [String]          // 9 simboluri (grilă 3x3) sau 6 numere la „numărul norocos”
    let luckyNumber: Int?
    /// Seria tipărită pe loz (decorativă) — identifică și lozul curent pentru resetarea răzuitului.
    let serial = Int.random(in: 100_000...999_999)

    init(type: TicketType) {
        self.price = type.price
        self.outcome = Outcome.random(weights: type.weights)
        self.prize = type.price * type.multiplier(for: outcome)

        if type.game == .luckyNumber {
            // 6 numere diferite; la câștig, unul dintre ele e chiar numărul norocos.
            let lucky = Int.random(in: 1...49)
            var numbers = Array((1...49).filter { $0 != lucky }.shuffled().prefix(6))
            if outcome != .lose { numbers[Int.random(in: 0..<6)] = lucky }
            self.luckyNumber = lucky
            self.symbols = numbers.map(String.init)
            return
        }
        self.luckyNumber = nil
        let all = type.symbols

        if outcome == .lose {
            // Fiecare simbol apare de cel mult 2 ori => niciun câștig posibil.
            symbols = Array((all + all).shuffled().prefix(9))
        } else {
            // Exact 3 simboluri câștigătoare, restul de cel mult 2 ori fiecare.
            let winning = type.symbol(for: outcome)
            let others = all.filter { $0 != winning }
            let filler = Array((others + others).shuffled().prefix(6))
            symbols = (Array(repeating: winning, count: 3) + filler).shuffled()
        }
    }
}

// MARK: - Componenta de răzuit (reutilizabilă)

struct ScratchCardView<Content: View>: View {
    var brushWidth: CGFloat = 38            // cam cât vârful degetului
    var revealThreshold: Double = 0.75      // peste 75% răzuit => se dezvăluie tot
    var showHint = false                    // degetul animat de la primul loz
    var foil: [Color] = TicketStyle.silverFoil   // culorile foliei
    var foilPattern = ""                         // semnul temei, presărat pe folie
    var onReveal: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var strokes: [[CGPoint]] = []
    @State private var crumbs: [CGRect] = []            // ciupituri pe marginea urmei
    @State private var lastPoint: CGPoint?
    @State private var scratchedCells: Set<Int> = []
    @State private var revealed = false
    @State private var hapticDistance: CGFloat = 0
    @AppStorage("tapToReveal") private var tapToReveal = false
    @State private var noise: [CGPoint] = (0..<600).map { _ in
        CGPoint(x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1))
    }
    private let grid = 30                   // grilă 30x30 pentru măsurarea suprafeței răzuite
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                content()
                    .frame(width: geo.size.width, height: geo.size.height)

                if !revealed {
                    Group {
                        if tapToReveal {
                            cover
                                .contentShape(Rectangle())
                                .onTapGesture { revealNow() }
                        } else {
                            cover
                                .mask(scratchMask)
                                .contentShape(Rectangle())
                                .gesture(scratchGesture(in: geo.size))
                        }
                    }
                    .overlay { if showHint && strokes.isEmpty && !tapToReveal { HintFinger() } }
                    .transition(.opacity)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// Folie metalică în culorile temei, cu granulație, ca la un loz adevărat.
    private var cover: some View {
        ZStack {
            LinearGradient(colors: foil, startPoint: .topLeading, endPoint: .bottomTrailing)
            PatternLayer(symbol: foilPattern, opacity: 0.22, size: 18, spacing: 40)
            Canvas { context, size in
                for (index, point) in noise.enumerated() {
                    let rect = CGRect(x: point.x * size.width, y: point.y * size.height, width: 1.5, height: 1.5)
                    let color = index % 2 == 0 ? Color.white.opacity(0.35) : Color.black.opacity(0.18)
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
            Text(L(tapToReveal ? "cover.tap" : "cover.scratch"))
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.black.opacity(0.5))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.35)))
        }
    }

    /// Masca: totul opac, mai puțin urmele degetului (șterse cu destinationOut).
    private var scratchMask: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
            context.blendMode = .destinationOut
            for stroke in strokes {
                var path = Path()
                path.addLines(stroke)
                context.stroke(path, with: .color(.black),
                               style: StrokeStyle(lineWidth: brushWidth, lineCap: .round, lineJoin: .round))
            }
            for crumb in crumbs {
                context.fill(Path(ellipseIn: crumb), with: .color(.black))
            }
        }
    }

    private func scratchGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let point = value.location
                if let last = lastPoint, !strokes.isEmpty {
                    strokes[strokes.count - 1].append(point)
                    scratch(from: last, to: point, in: size)
                } else {
                    strokes.append([point, point])
                    haptic.prepare()
                    scratch(from: point, to: point, in: size)
                }
                lastPoint = point
                checkReveal()               // se dezvăluie chiar în timpul răzuitului
            }
            .onEnded { _ in lastPoint = nil }
    }

    /// Parcurge segmentul dintre două poziții ale degetului, ca să conteze și mișcările rapide.
    private func scratch(from start: CGPoint, to end: CGPoint, in size: CGSize) {
        let distance = hypot(end.x - start.x, end.y - start.y)
        let steps = max(1, Int(distance / (brushWidth / 4)))
        let radius = brushWidth / 2

        for step in 0...steps {
            let t = CGFloat(step) / CGFloat(steps)
            let point = CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t)
            markCells(around: point, radius: radius, in: size)

            // Margini neregulate: mici ciupituri în jurul urmei.
            if Bool.random() {
                let angle = CGFloat.random(in: 0..<(2 * .pi))
                let reach = radius + CGFloat.random(in: -2...5)
                let r = CGFloat.random(in: 1.5...4)
                crumbs.append(CGRect(x: point.x + cos(angle) * reach - r,
                                     y: point.y + sin(angle) * reach - r,
                                     width: r * 2, height: r * 2))
            }
        }

        // Vibrație fină la fiecare ~14 puncte parcurse.
        hapticDistance += distance
        if hapticDistance > 14 {
            if Feedback.hapticsOn { haptic.impactOccurred(intensity: 0.6) }
            hapticDistance = 0
        }
    }

    /// Marchează celulele din grilă al căror centru e sub deget.
    private func markCells(around point: CGPoint, radius: CGFloat, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let cellW = size.width / CGFloat(grid)
        let cellH = size.height / CGFloat(grid)
        let col0 = max(0, Int(((point.x - radius) / cellW).rounded(.down)))
        let col1 = min(grid - 1, Int(((point.x + radius) / cellW).rounded(.down)))
        let row0 = max(0, Int(((point.y - radius) / cellH).rounded(.down)))
        let row1 = min(grid - 1, Int(((point.y + radius) / cellH).rounded(.down)))
        guard col0 <= col1, row0 <= row1 else { return }   // degetul a ieșit din loz

        for row in row0...row1 {
            for col in col0...col1 {
                let centerX = (CGFloat(col) + 0.5) * cellW
                let centerY = (CGFloat(row) + 0.5) * cellH
                if hypot(centerX - point.x, centerY - point.y) <= radius {
                    scratchedCells.insert(row * grid + col)
                }
            }
        }
    }

    private func checkReveal() {
        let progress = Double(scratchedCells.count) / Double(grid * grid)
        guard progress >= revealThreshold else { return }
        revealNow()
    }

    private func revealNow() {
        guard !revealed else { return }
        withAnimation(.easeOut(duration: 0.4)) { revealed = true }
        if Feedback.hapticsOn { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        onReveal()
    }
}

// MARK: - Ecranul de loz

struct TicketScreen: View {
    @AppStorage("coins") private var coins = 1500
    @State private var ticket: Ticket?
    @State private var resultText = ""
    @State private var settled = true
    @State private var lastLosingMessage = ""
    @State private var shareImage: Image?
    @State private var sharePNG: Data?
    @State private var showMessageComposer = false
    @State private var showConfetti = false
    @AppStorage("didOnboard") private var didOnboard = false
    @AppStorage("seenMessages") private var seenMessages = ""
    @AppStorage("lastFreeTicketTime") private var lastFreeTicketTime: Double = 0
    let type: TicketType
    /// true când ecranul e deschis din butonul „loz gratuit” din lobby.
    var useFreeTicket = false
    /// true la prima deschidere a aplicației: loz gratuit, cu indiciu de răzuit.
    var isWelcome = false
    private var price: Int { type.price }
    private var freeAvailable: Bool {
        useFreeTicket && Date().timeIntervalSince1970 - lastFreeTicketTime >= freeTicketInterval
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(verbatim: "💰 \(coins)").font(.title2.bold())
                .navigationTitle(type.title)
                .navigationBarTitleDisplayMode(.inline)

            if let ticket {
                if let lucky = ticket.luckyNumber {
                    Text(L("lucky.number", "\(lucky)")).font(.title3.bold())
                }
                TicketFrame(type: type, serial: ticket.serial) {
                    ScratchCardView(showHint: isWelcome, foil: type.style.foil, foilPattern: type.style.pattern,
                                    onReveal: { settle(ticket) }) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                            ForEach(Array(ticket.symbols.enumerated()), id: \.offset) { _, symbol in
                                Text(symbol)
                                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color.black)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white.opacity(0.94))
                    }
                    .frame(height: 230)
                    .id(ticket.serial)   // resetează răzuitul la loz nou
                }
            } else {
                // Niciun loz cumpărat încă: lozul „sigilat”, cu folia întreagă.
                TicketFrame(type: type) {
                    ZStack {
                        LinearGradient(colors: type.style.foil, startPoint: .topLeading, endPoint: .bottomTrailing)
                        PatternLayer(symbol: type.style.pattern, opacity: 0.22, size: 18, spacing: 40)
                        Text(L("ticket.empty"))
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.55))
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(height: 230)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            Text(resultText).font(.headline).multilineTextAlignment(.center)

            if let shareImage {
                HStack(spacing: 16) {
                    ShareLink(item: shareImage, preview: SharePreview(appName, image: shareImage)) {
                        Label(L("share.friend"), systemImage: "square.and.arrow.up")
                    }
                    if MFMessageComposeViewController.canSendText() {
                        Button { showMessageComposer = true } label: {
                            Label(L("share.messages"), systemImage: "message.fill")
                        }
                    }
                }
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }

            Button(freeAvailable ? L("buy.free") : L("buy.paid", "\(price)")) { buy() }
                .buttonStyle(.borderedProminent)
                .disabled(!freeAvailable && coins < price)
        }
        .padding()
        .overlay { if showConfetti { ConfettiView() } }
        .onAppear {
            // Primul loz e din partea casei.
            if isWelcome && !didOnboard && ticket == nil {
                didOnboard = true
                settled = false
                ticket = Ticket(type: type)
                resultText = L("welcome")
            }
        }
        .sheet(isPresented: $showMessageComposer) {
            MessageComposer(text: resultText + "\n— " + appName, imageData: sharePNG)
                .ignoresSafeArea()
        }
        // Dacă jucătorul iese fără să răzuiască, premiul se plătește oricum.
        .onDisappear { if let ticket { settle(ticket, celebrate: false) } }
    }

    private func buy() {
        if let ticket { settle(ticket, celebrate: false) }      // lozul anterior nerăzuit nu se pierde
        if freeAvailable {
            lastFreeTicketTime = Date().timeIntervalSince1970
            Reminders.freeTicketReady()
        } else {
            coins -= price
        }
        resultText = ""
        shareImage = nil
        sharePNG = nil
        showConfetti = false
        settled = false
        ticket = Ticket(type: type)
    }

    /// `celebrate` e false când lozul se încheie singur (jucătorul a ieșit sau a cumpărat altul).
    private func settle(_ ticket: Ticket, celebrate: Bool = true) {
        guard !settled else { return }
        settled = true
        coins += ticket.prize
        if celebrate {
            if ticket.prize > 0 {
                Feedback.win()
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { showConfetti = false }
            } else {
                Feedback.lose()
            }
        }
        resultText = ticket.prize > 0 ? L("win", "\(ticket.prize)") : nextLosingMessage()

        // Imaginea pentru butonul „Trimite”.
        let renderer = ImageRenderer(content: ShareCard(text: resultText, emoji: type.emoji))
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            shareImage = Image(uiImage: uiImage)
            sharePNG = uiImage.pngData()
        }
        Stats.recordTicket(ticket)
    }

    /// Alege un mesaj la întâmplare, dar niciodată același de două ori la rând.
    private func nextLosingMessage() -> String {
        let message = Self.losingMessages.filter { $0 != resultText && $0 != lastLosingMessage }.randomElement()
            ?? Self.losingMessages[0]
        lastLosingMessage = message
        // Mesajul intră în colecția jucătorului.
        if let index = Self.losingMessages.firstIndex(of: message) {
            var seen = seenMessageIndices(seenMessages)
            seen.insert(index)
            seenMessages = seen.sorted().map(String.init).joined(separator: ",")
        }
        return message
    }

    /// Cele 20 de mesaje (glume și sfaturi), în limba telefonului: cheile msg.0 … msg.19.
    static let losingMessageCount = 20
    static var losingMessages: [String] {
        (0..<losingMessageCount).map { L("msg.\($0)") }
    }
}

/// Un loz gratuit la fiecare 4 ore.
let freeTicketInterval: Double = 4 * 60 * 60

// MARK: - Tipuri de lozuri

struct TicketType: Identifiable, Hashable {
    let id: String
    /// Cheia numelui din tabelul de traduceri (ex. "ticket.bronze").
    let name: String
    var title: String { L(name) }
    let emoji: String
    let price: Int
    let color: Color
    /// Șanse în procente, în ordinea: pierdere, miza înapoi, premiu mediu, jackpot (total 100).
    let weights: [Int]
    /// Multiplicatori pe preț, în aceeași ordine.
    let multipliers: [Int]
    /// 6 simboluri; primele trei sunt cele câștigătoare: miza înapoi, premiu mediu, jackpot.
    var symbols: [String] = ["🍒", "💎", "👑", "🍋", "⭐️", "🔔"]
    /// nil = disponibil tot anul; altfel doar în perioada dată.
    var season: Season? = nil
    var game: GameKind = .matchThree

    func symbol(for outcome: Outcome) -> String {
        switch outcome {
        case .lose: return ""
        case .moneyBack: return symbols[0]
        case .medium: return symbols[1]
        case .jackpot: return symbols[2]
        }
    }

    /// Lozurile care se pot juca azi (cele permanente + edițiile limitate active).
    static var available: [TicketType] {
        all.filter { $0.season?.contains(Date()) ?? true }
    }

    func multiplier(for outcome: Outcome) -> Int {
        multipliers[Outcome.allCases.firstIndex(of: outcome) ?? 0]
    }

    static let all: [TicketType] = [
        // Câștiguri dese și mici — returnare medie 86%
        TicketType(id: "bronze", name: "ticket.bronze", emoji: "🥉", price: 50, color: .brown,
                   weights: [60, 30, 9, 1], multipliers: [0, 1, 4, 20]),
        // Echilibrat — returnare medie 95%
        TicketType(id: "silver", name: "ticket.silver", emoji: "🥈", price: 100, color: .gray,
                   weights: [65, 25, 9, 1], multipliers: [0, 1, 5, 25]),
        // Câștiguri rare și mari — returnare medie 94%
        TicketType(id: "gold", name: "ticket.gold", emoji: "🥇", price: 500, color: .yellow,
                   weights: [80, 12, 7, 1], multipliers: [0, 1, 6, 40]),

        // Alt tip de joc: numărul norocos printre 6 numere — returnare medie 88%
        TicketType(id: "lucky", name: "ticket.lucky", emoji: "🍀", price: 150, color: .mint,
                   weights: [72, 18, 9, 1], multipliers: [0, 1, 5, 25],
                   game: .luckyNumber),

        // --- Teme permanente ---
        // Dulciuri: ieftin, câștiguri dese — returnare medie 86%
        TicketType(id: "sweets", name: "ticket.sweets", emoji: "🍭", price: 50, color: .pink,
                   weights: [55, 35, 9, 1], multipliers: [0, 1, 4, 15],
                   symbols: ["🍬", "🍩", "🧁", "🍫", "🍪", "🍭"]),
        // Ocean — returnare medie 95%
        TicketType(id: "ocean", name: "ticket.ocean", emoji: "🌊", price: 100, color: .blue,
                   weights: [65, 25, 9, 1], multipliers: [0, 1, 5, 25],
                   symbols: ["🐚", "🐠", "🐙", "🦀", "⚓️", "🌴"]),
        // Safari — returnare medie 95%
        TicketType(id: "safari", name: "ticket.safari", emoji: "🦁", price: 150, color: .orange,
                   weights: [65, 25, 9, 1], multipliers: [0, 1, 5, 25],
                   symbols: ["🦓", "🦒", "🦁", "🐘", "🦏", "🌿"]),
        // Spațiu — returnare medie 95%
        TicketType(id: "space", name: "ticket.space", emoji: "🚀", price: 200, color: .indigo,
                   weights: [70, 20, 9, 1], multipliers: [0, 1, 5, 30],
                   symbols: ["⭐️", "🪐", "🚀", "👽", "🌙", "☄️"]),
        // Pirați: scump, câștiguri rare și mari — returnare medie 98%
        TicketType(id: "pirates", name: "ticket.pirates", emoji: "🏴‍☠️", price: 300, color: .brown,
                   weights: [76, 15, 8, 1], multipliers: [0, 1, 6, 35],
                   symbols: ["🗝️", "🦜", "💎", "⚓️", "🗺️", "⚔️"]),

        // --- Ediții limitate ---
        TicketType(id: "valentine", name: "ticket.valentine", emoji: "❤️", price: 100, color: .red,
                   weights: [65, 25, 9, 1], multipliers: [0, 1, 5, 25],
                   symbols: ["🌹", "💌", "💍", "🍫", "🧸", "💘"],
                   season: Season(fromMonth: 2, fromDay: 8, toMonth: 2, toDay: 15)),
        TicketType(id: "halloween", name: "ticket.halloween", emoji: "🎃", price: 100, color: .orange,
                   weights: [65, 25, 9, 1], multipliers: [0, 1, 5, 25],
                   symbols: ["🍬", "👻", "🎃", "🦇", "🕷️", "🕯️"],
                   season: Season(fromMonth: 10, fromDay: 24, toMonth: 11, toDay: 1)),
        TicketType(id: "newyear", name: "ticket.newyear", emoji: "🎆", price: 200, color: .indigo,
                   weights: [65, 25, 9, 1], multipliers: [0, 1, 5, 25],
                   symbols: ["🥂", "🎆", "🍾", "🎉", "🕛", "✨"],
                   season: Season(fromMonth: 12, fromDay: 28, toMonth: 12, toDay: 31)),
        TicketType(id: "dec1", name: "ticket.dec1", emoji: "🇷🇴", price: 100, color: .blue,
                   weights: [60, 28, 10, 2], multipliers: [0, 1, 4, 15],
                   symbols: ["🇷🇴", "🦅", "🏰", "🌄", "🎺", "🥁"],
                   season: Season(fromMonth: 11, fromDay: 25, toMonth: 12, toDay: 2)),
        TicketType(id: "christmas", name: "ticket.christmas", emoji: "🎄", price: 200, color: .green,
                   weights: [65, 25, 9, 1], multipliers: [0, 1, 5, 25],
                   symbols: ["🎁", "⭐️", "🎅", "🎄", "❄️", "🔔"],
                   season: Season(fromMonth: 12, fromDay: 10, toMonth: 12, toDay: 27)),
        // Paștele își schimbă data în fiecare an: perioada de mai jos e pentru 2027 (2 mai).
        TicketType(id: "easter", name: "ticket.easter", emoji: "🐣", price: 100, color: .pink,
                   weights: [65, 25, 9, 1], multipliers: [0, 1, 5, 25],
                   symbols: ["🥚", "🐣", "🐰", "🌷", "🧺", "🕯️"],
                   season: Season(fromMonth: 4, fromDay: 20, toMonth: 5, toDay: 5)),
    ]
}

/// Perioadă din an (inclusiv capetele), aceeași în fiecare an. Nu trece peste Anul Nou.
struct Season: Hashable {
    let fromMonth: Int, fromDay: Int, toMonth: Int, toDay: Int

    func contains(_ date: Date) -> Bool {
        let parts = Calendar.current.dateComponents([.month, .day], from: date)
        let value = (parts.month ?? 0) * 100 + (parts.day ?? 0)
        return value >= fromMonth * 100 + fromDay && value <= toMonth * 100 + toDay
    }
}

// MARK: - Imaginea trimisă prietenilor

struct ShareCard: View {
    let text: String
    let emoji: String

    var body: some View {
        VStack(spacing: 20) {
            Text(emoji).font(.system(size: 72))
            Text(text)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.white)
            Text(L("share.tagline", appName))
                .font(.footnote)
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .padding(32)
        .frame(width: 360, height: 360)
        .background(LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom))
    }
}

// MARK: - Ecranul de mesaje (colecție + contact)

struct MessagesScreen: View {
    @AppStorage("seenMessages") private var seenMessages = ""

    var body: some View {
        let seen = seenMessageIndices(seenMessages)
        let all = TicketScreen.losingMessages

        List {
            Section(L("messages.collection", "\(seen.count)", "\(all.count)")) {
                ForEach(Array(all.enumerated()), id: \.offset) { index, message in
                    if seen.contains(index) {
                        HStack {
                            Text(message)
                            Spacer()
                            ShareLink(item: message + "\n— " + appName) {
                                Image(systemName: "square.and.arrow.up")
                            }
                            .buttonStyle(.borderless)
                        }
                    } else {
                        Text(L("messages.locked")).foregroundStyle(.secondary)
                    }
                }
            }

            Section(L("messages.contact")) {
                if let subject = appName.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
                   let url = URL(string: "mailto:\(supportEmail)?subject=\(subject)") {
                    Link(L("messages.contact.link"), destination: url)
                }
            }
        }
        .navigationTitle(L("messages.title"))
    }
}

// MARK: - Trimitere prin aplicația Mesaje (iMessage / SMS)

struct MessageComposer: UIViewControllerRepresentable {
    let text: String
    let imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: { dismiss() })
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.body = text
        if let imageData {
            controller.addAttachmentData(imageData, typeIdentifier: "public.png", filename: "ticket.png")
        }
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: MFMessageComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }

        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                          didFinishWith result: MessageComposeResult) {
            onFinish()
        }
    }
}

// MARK: - Notificări locale (fără server)

enum Reminders {
    /// Cere permisiunea la prima folosire, apoi programează notificarea (înlocuind-o pe cea veche cu același id).
    private static func schedule(id: String, title: String, body: String, trigger: UNNotificationTrigger) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            center.removePendingNotificationRequests(withIdentifiers: [id])
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    /// Peste 4 ore: „lozul gratuit e gata”.
    static func freeTicketReady() {
        schedule(id: "freeTicket", title: L("notif.free.title"),
                 body: L("notif.free.body"),
                 trigger: UNTimeIntervalNotificationTrigger(timeInterval: freeTicketInterval, repeats: false))
    }

    /// Mâine la 19:00: „nu-ți pierde seria”.
    static func streakReminder(day: Int) {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return }
        var parts = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        parts.hour = 19
        schedule(id: "streak", title: L("notif.streak.title", "\(day)"),
                 body: L("notif.streak.body"),
                 trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
    }
}

// MARK: - Game Center (clasament între prieteni)

enum GameCenter {
    /// Trebuie să fie identic cu ID-ul clasamentului creat în App Store Connect.
    static let leaderboardID = "scratchsmile.coins"

    static func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { viewController, _ in
            guard let viewController else { return }
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            scene?.keyWindow?.rootViewController?.present(viewController, animated: true)
        }
    }

    static func submit(coins: Int) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        GKLeaderboard.submitScore(coins, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [leaderboardID]) { _ in }
    }

    static func showLeaderboard() {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        GKAccessPoint.shared.trigger(state: .leaderboards) { }
    }
}

// MARK: - Lobby (ecranul principal)

struct LobbyScreen: View {
    @AppStorage("coins") private var coins = 1500
    @AppStorage("lastBonusTime") private var lastBonusTime: Double = 0
    @AppStorage("bonusStreak") private var bonusStreak = 0
    @AppStorage("lastFreeTicketTime") private var lastFreeTicketTime: Double = 0
    @State private var showFreeTicket = false
    @State private var showWelcome = false
    @AppStorage("didOnboard") private var didOnboard = false

    private var lastBonusDate: Date { Date(timeIntervalSince1970: lastBonusTime) }

    private var bonusAvailable: Bool {
        !Calendar.current.isDateInToday(lastBonusDate)
    }

    /// Ziua din serie pe care ar primi-o următorul bonus (1...7).
    /// Seria continuă doar dacă ultimul bonus a fost luat ieri; altfel repornește de la 1.
    private var nextStreakDay: Int {
        Calendar.current.isDateInYesterday(lastBonusDate) ? min(bonusStreak + 1, 7) : 1
    }

    /// 300 în ziua 1, apoi +100 pe zi, până la 900 în ziua 7.
    private var dailyBonus: Int { 300 + 100 * (nextStreakDay - 1) }

    private func freeTicketLabel(at now: Date) -> String? {
        let remaining = freeTicketInterval - (now.timeIntervalSince1970 - lastFreeTicketTime)
        guard remaining > 0 else { return nil }
        let minutes = Int(remaining / 60) + 1
        return L("lobby.free.wait", "\(minutes / 60)h \(minutes % 60)m")
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(verbatim: "💰 \(coins)").font(.title.bold())
                    Button(bonusAvailable
                           ? L("lobby.bonus.claim", "\(nextStreakDay)", "\(dailyBonus)")
                           : L("lobby.bonus.taken", "\(bonusStreak)")) {
                        let day = nextStreakDay
                        coins += dailyBonus
                        bonusStreak = day
                        lastBonusTime = Date().timeIntervalSince1970
                        Reminders.streakReminder(day: day)
                        Stats.recordStreak(day)
                    }
                    .disabled(!bonusAvailable)

                    // Se reîmprospătează singur în fiecare minut.
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        let waiting = freeTicketLabel(at: context.date)
                        Button(waiting ?? L("lobby.free")) { showFreeTicket = true }
                            .disabled(waiting != nil)
                    }

                    Button(L("lobby.leaderboard")) { GameCenter.showLeaderboard() }
                    NavigationLink(L("lobby.messages")) { MessagesScreen() }
                }

                Section(L("lobby.choose")) {
                    ForEach(TicketType.available) { type in
                        NavigationLink(value: type) {
                            HStack(spacing: 12) {
                                Text(type.emoji).font(.system(size: 40))
                                VStack(alignment: .leading, spacing: 3) {
                                    if type.season != nil {
                                        Text(L("lobby.limited"))
                                            .font(.system(.caption2, design: .rounded).weight(.heavy))
                                            .foregroundStyle(Color.black.opacity(0.8))
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Color.yellow))
                                    }
                                    Text(type.title)
                                        .font(.system(.headline, design: .rounded).weight(.heavy))
                                        .foregroundStyle(Color.white)
                                    Text(L("lobby.ticket.info", "\(type.price)", "\(type.price * type.multiplier(for: .jackpot))"))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.white.opacity(0.85))
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(
                            ZStack {
                                type.backgroundGradient
                                PatternLayer(symbol: type.style.pattern, opacity: 0.14)
                            }
                        )
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text(L("lobby.disclaimer"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(.bar)
            }
            .navigationTitle(appName)
            .onAppear {
                GameCenter.authenticate()
                GameCenter.submit(coins: coins)
                if !didOnboard { showWelcome = true }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink { StatsScreen() } label: { Image(systemName: "chart.bar.fill") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { SettingsScreen() } label: { Image(systemName: "gearshape.fill") }
                }
            }
            .navigationDestination(isPresented: $showWelcome) {
                TicketScreen(type: TicketType.all[0], isWelcome: true)
            }
            .onChange(of: coins) { GameCenter.submit(coins: coins) }
            .navigationDestination(for: TicketType.self) { type in
                TicketScreen(type: type)
            }
            .navigationDestination(isPresented: $showFreeTicket) {
                TicketScreen(type: TicketType.all[0], useFreeTicket: true)
            }
        }
    }
}

#Preview {
    LobbyScreen()
}
