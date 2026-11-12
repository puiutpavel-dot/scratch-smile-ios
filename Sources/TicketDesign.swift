import SwiftUI

// MARK: - Aspectul fiecărui loz

extension Color {
    /// Culoare din cod hex, ex. Color(hex: 0xD4AF37).
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

struct TicketStyle {
    /// Fundalul lozului (degrade, de sus-stânga spre jos-dreapta).
    let background: [Color]
    /// Folia care se răzuiește.
    let foil: [Color]
    /// Semnul presărat discret pe fundal și pe folie.
    let pattern: String

    static let silverFoil = [Color(hex: 0x9EA3A8), Color(hex: 0xDBDEE1), Color(hex: 0x94999E),
                             Color(hex: 0xCCD0D3), Color(hex: 0x999EA3)]
    static let goldFoil = [Color(hex: 0xD4AF37), Color(hex: 0xFFF1A8), Color(hex: 0xC99A1E)]

    static let classic = TicketStyle(background: [Color(hex: 0x5C6B7A), Color(hex: 0x9FB0C0)],
                                     foil: silverFoil, pattern: "✦")

    /// Aspectul după id-ul lozului din `TicketType.all`. Un loz fără intrare aici arată „clasic”.
    static let byID: [String: TicketStyle] = [
        "bronze": TicketStyle(background: [Color(hex: 0x8C5A2B), Color(hex: 0xC98B4E)],
                              foil: [Color(hex: 0xB87333), Color(hex: 0xE0A878), Color(hex: 0xA0622D)], pattern: "✦"),
        "silver": classic,
        "gold": TicketStyle(background: [Color(hex: 0xB8860B), Color(hex: 0xF2C94C)], foil: goldFoil, pattern: "★"),
        "lucky": TicketStyle(background: [Color(hex: 0x0B6E4F), Color(hex: 0x3FBF7F)],
                             foil: [Color(hex: 0x5FAF7A), Color(hex: 0xC9F0D4), Color(hex: 0x4A9A68)], pattern: "🍀"),
        "ocean": TicketStyle(background: [Color(hex: 0x0A4D8C), Color(hex: 0x27B5D6)],
                             foil: [Color(hex: 0x5AA9C9), Color(hex: 0xD2F1F7), Color(hex: 0x3E8FB5)], pattern: "🌊"),
        "space": TicketStyle(background: [Color(hex: 0x1B1147), Color(hex: 0x5B2A9D)],
                             foil: [Color(hex: 0x6C63B5), Color(hex: 0xC9C4F2), Color(hex: 0x514A9E)], pattern: "✨"),
        "sweets": TicketStyle(background: [Color(hex: 0xE0559A), Color(hex: 0xFF9EC4)],
                              foil: [Color(hex: 0xF3A6C8), Color(hex: 0xFFE3EF), Color(hex: 0xE78AB4)], pattern: "🍬"),
        "pirates": TicketStyle(background: [Color(hex: 0x3B2A1A), Color(hex: 0x8A5A2B)],
                               foil: [Color(hex: 0x9C8A6A), Color(hex: 0xE6D9B8), Color(hex: 0x84724F)], pattern: "☠️"),
        "safari": TicketStyle(background: [Color(hex: 0xB5651D), Color(hex: 0xE6B34A)],
                              foil: [Color(hex: 0xC9A66B), Color(hex: 0xF3E2B8), Color(hex: 0xB08D4F)], pattern: "🐾"),
        "dec1": TicketStyle(background: [Color(hex: 0x002B7F), Color(hex: 0xCE1126)],
                            foil: [Color(hex: 0xFCD116), Color(hex: 0xFFF0A0), Color(hex: 0xE0B800)], pattern: "🇷🇴"),
        "christmas": TicketStyle(background: [Color(hex: 0x0F6B3A), Color(hex: 0xC0392B)],
                                 foil: [Color(hex: 0xD9DDE2), Color(hex: 0xFFFFFF), Color(hex: 0xC2C8CF)], pattern: "❄️"),
        "easter": TicketStyle(background: [Color(hex: 0x8E6BBF), Color(hex: 0xF6A6C1)],
                              foil: [Color(hex: 0xF7E38A), Color(hex: 0xFFF7C9), Color(hex: 0xEDD060)], pattern: "🌷"),
        "halloween": TicketStyle(background: [Color(hex: 0x2B1B3D), Color(hex: 0xE67E22)],
                                 foil: [Color(hex: 0xF39C4A), Color(hex: 0xFFD9A8), Color(hex: 0xD9822B)], pattern: "🦇"),
        "valentine": TicketStyle(background: [Color(hex: 0xB3123B), Color(hex: 0xFF6B8B)],
                                 foil: [Color(hex: 0xF2A0B5), Color(hex: 0xFFE0E8), Color(hex: 0xE5839D)], pattern: "❤️"),
        "newyear": TicketStyle(background: [Color(hex: 0x0B1026), Color(hex: 0x2C3E73)], foil: goldFoil, pattern: "✨"),
    ]
}

extension TicketType {
    var style: TicketStyle { TicketStyle.byID[id] ?? .classic }

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: style.background, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Forma de loz (colțuri rotunjite + două crestături laterale)

struct TicketShape: Shape {
    var cornerRadius: CGFloat = 20
    var notchRadius: CGFloat = 11
    /// La ce înălțime sunt crestăturile, măsurat de sus.
    var notchY: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: cornerRadius)
        for x in [rect.minX, rect.maxX] {
            path.addEllipse(in: CGRect(x: x - notchRadius, y: rect.minY + notchY - notchRadius,
                                       width: notchRadius * 2, height: notchRadius * 2))
        }
        return path      // se umple cu regula par-impar, deci cercurile devin găuri
    }
}

/// Semnul temei, presărat în rânduri decalate.
struct PatternLayer: View {
    let symbol: String
    var opacity: Double = 0.16
    var size: CGFloat = 22
    var spacing: CGFloat = 46

    var body: some View {
        Canvas { context, canvasSize in
            guard !symbol.isEmpty else { return }
            let mark = context.resolve(Text(symbol).font(.system(size: size)).foregroundColor(.white))
            var row = 0
            var y: CGFloat = spacing / 2
            while y < canvasSize.height + spacing {
                var x: CGFloat = row % 2 == 0 ? spacing / 2 : spacing
                while x < canvasSize.width + spacing {
                    context.draw(mark, at: CGPoint(x: x, y: y))
                    x += spacing
                }
                y += spacing * 0.8
                row += 1
            }
        }
        .opacity(opacity)
        .allowsHitTesting(false)
    }
}

// MARK: - Rama lozului: antet, zona de joc, tabelul de premii

struct TicketFrame<Content: View>: View {
    let type: TicketType
    /// Seria tipărită pe loz; nil cât timp nu e cumpărat niciun loz.
    var serial: Int?
    @ViewBuilder var content: () -> Content

    private let headerHeight: CGFloat = 64

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: headerHeight)

            // Linia punctată de „rupere”
            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(height: 1.5)
                .padding(.horizontal, 16)

            content()
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 20).fill(Palette.goldGradient))
                .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
                .padding(.horizontal, 12)
                .padding(.top, 12)

            footer
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        }
        .background {
            ZStack {
                type.backgroundGradient
                PatternLayer(symbol: type.style.pattern)
            }
        }
        // Chenar punctat interior + ramă aurie pe conturul biletului.
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))
                .padding(6)
                .allowsHitTesting(false)
        }
        .overlay {
            TicketShape(notchY: headerHeight)
                .stroke(Palette.goldGradient, lineWidth: 6)
                .allowsHitTesting(false)
        }
        .clipShape(TicketShape(notchY: headerHeight), style: FillStyle(eoFill: true))
        .shadow(color: (type.style.background.last ?? .black).opacity(0.6), radius: 12, y: 6)
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RotatingBurst().frame(width: 70, height: 70)
                Text(type.emoji).font(.system(size: 36)).shadow(color: Color.black.opacity(0.4), radius: 3, y: 2)
            }
            .frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text(type.title)
                    .font(.system(.title3, design: .rounded).weight(.black))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.black.opacity(0.5), radius: 2, y: 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let serial {
                    Text(verbatim: "Nº \(serial)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.75))
                }
            }
            Spacer(minLength: 4)
            Text(verbatim: "\(type.price) 💰")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Color.black.opacity(0.8))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Palette.goldGradient))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.7), lineWidth: 1))
        }
        .padding(.horizontal, 16)
    }

    /// Regula de câștig, apoi tabelul de premii: ce aduce fiecare combinație câștigătoare.
    private var footer: some View {
        VStack(spacing: 6) {
            Text(L(type.game == .luckyNumber ? "rule.lucky" : "rule.match3"))
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.3)))
            prizeTable
        }
    }

    private var prizeTable: some View {
        HStack(spacing: 0) {
            ForEach(Array([Outcome.moneyBack, .medium, .jackpot].enumerated()), id: \.offset) { index, outcome in
                if index > 0 { Spacer(minLength: 4) }
                let prize = type.price * type.multiplier(for: outcome)
                Text(verbatim: type.game == .luckyNumber
                     ? "🍀\(String(repeating: "★", count: index + 1)) \(prize)"
                     : "\(type.symbol(for: outcome))×3 = \(prize)")
                    .font(.system(.caption, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color(hex: 0xFFE27A))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.4)))
                    .overlay(Capsule().strokeBorder(Palette.goldGradient, lineWidth: 1))
            }
        }
    }
}
