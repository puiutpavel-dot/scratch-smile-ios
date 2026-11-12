import SwiftUI

// MARK: - Culori și elemente grafice comune

enum Palette {
    static let gold = [Color(hex: 0xFFF3B0), Color(hex: 0xE2B93B), Color(hex: 0x9A6F12), Color(hex: 0xFFE27A)]
    static var goldGradient: LinearGradient {
        LinearGradient(colors: gold, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static let night = [Color(hex: 0x1A0B3B), Color(hex: 0x3A1466), Color(hex: 0x0E1F4D)]
}

/// Fundalul aplicației: noapte violet, pete de lumină colorată și stele care clipesc.
struct AppBackground: View {
    private struct Star {
        let x = CGFloat.random(in: 0...1)
        let y = CGFloat.random(in: 0...1)
        let size = CGFloat.random(in: 1...3.2)
        let speed = Double.random(in: 0.6...2.2)
        let phase = Double.random(in: 0...6.28)
    }

    @State private var stars: [Star] = (0..<70).map { _ in Star() }

    var body: some View {
        ZStack {
            LinearGradient(colors: Palette.night, startPoint: .top, endPoint: .bottom)
            Circle().fill(Color(hex: 0xFF4FA3).opacity(0.28))
                .frame(width: 320, height: 320).blur(radius: 90).offset(x: -140, y: -260)
            Circle().fill(Color(hex: 0x39C6FF).opacity(0.22))
                .frame(width: 360, height: 360).blur(radius: 100).offset(x: 160, y: 120)
            Circle().fill(Color(hex: 0xFFC83D).opacity(0.18))
                .frame(width: 300, height: 300).blur(radius: 90).offset(x: -120, y: 420)
            TimelineView(.animation(minimumInterval: 1.0 / 20)) { timeline in
                Canvas { context, size in
                    let t = timeline.date.timeIntervalSinceReferenceDate
                    for star in stars {
                        let alpha = 0.25 + 0.75 * (0.5 + 0.5 * sin(t * star.speed + star.phase))
                        let rect = CGRect(x: star.x * size.width, y: star.y * size.height,
                                          width: star.size, height: star.size)
                        context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(alpha)))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

/// O dungă de lumină care trece periodic peste element. Elementul trebuie decupat (clipShape) după.
struct Shine: ViewModifier {
    var period: Double = 4
    var phase: Double = 0

    func body(content: Content) -> some View {
        content.overlay {
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                GeometryReader { geo in
                    let raw = (timeline.date.timeIntervalSinceReferenceDate + phase)
                        .truncatingRemainder(dividingBy: period) / period
                    let progress = min(raw / 0.4, 1)          // trece în 40% din perioadă, apoi pauză
                    let width = geo.size.width
                    LinearGradient(colors: [Color.white.opacity(0), Color.white.opacity(0.5), Color.white.opacity(0)],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: max(width * 0.35, 30), height: geo.size.height * 1.8)
                        .rotationEffect(.degrees(20))
                        .offset(x: -width * 0.6 + CGFloat(progress) * width * 2.2, y: -geo.size.height * 0.4)
                }
            }
            .blendMode(.screen)
            .allowsHitTesting(false)
        }
    }
}

/// Raze de lumină în jurul unui punct.
struct Starburst: Shape {
    var rays = 14

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        for index in 0..<rays {
            let start = CGFloat(index) * 2 * .pi / CGFloat(rays)
            let end = start + .pi / CGFloat(rays)
            path.move(to: center)
            path.addLine(to: CGPoint(x: center.x + cos(start) * radius, y: center.y + sin(start) * radius))
            path.addLine(to: CGPoint(x: center.x + cos(end) * radius, y: center.y + sin(end) * radius))
            path.closeSubpath()
        }
        return path
    }
}

/// Razele, rotindu-se încet și estompate spre margine.
struct RotatingBurst: View {
    @State private var spin = false

    var body: some View {
        GeometryReader { geo in
            Starburst()
                .fill(Color.white.opacity(0.2))
                .rotationEffect(.degrees(spin ? 360 : 0))
                .mask(RadialGradient(colors: [Color.white, Color.white.opacity(0)], center: .center,
                                     startRadius: 6, endRadius: min(geo.size.width, geo.size.height) / 2))
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 26).repeatForever(autoreverses: false)) { spin = true }
        }
    }
}

// MARK: - Butoane

/// Buton mare, lucios, în stil de joc.
struct GlossyButtonStyle: ButtonStyle {
    var colors: [Color] = [Color(hex: 0xFFD84D), Color(hex: 0xF29F05)]
    var textColor = Color(hex: 0x3A2400)
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.heavy))
            .foregroundStyle(textColor)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    Capsule().fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                    Capsule()
                        .fill(LinearGradient(colors: [Color.white.opacity(0.55), Color.white.opacity(0)],
                                             startPoint: .top, endPoint: .center))
                        .padding(3)
                    Capsule().strokeBorder(Color.white.opacity(0.65), lineWidth: 1.5)
                }
            }
            .shadow(color: (colors.last ?? .orange).opacity(0.6),
                    radius: configuration.isPressed ? 2 : 8, y: configuration.isPressed ? 1 : 5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .saturation(isEnabled ? 1 : 0.15)
            .opacity(isEnabled ? 1 : 0.6)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Buton mic, din „sticlă”, pentru acțiuni secundare.
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.white.opacity(configuration.isPressed ? 0.28 : 0.14)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 1))
    }
}

// MARK: - Panoul cu monede

struct WalletPanel: View {
    let coins: Int

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RotatingBurst().frame(width: 84, height: 84)
                Text(verbatim: "💰").font(.system(size: 46)).shadow(color: Color.black.opacity(0.4), radius: 4, y: 2)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(L("wallet.title"))
                    .font(.system(.caption, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color(hex: 0xFFE27A))
                Text(verbatim: "\(coins)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.goldGradient)
                    .shadow(color: Color.black.opacity(0.5), radius: 2, y: 2)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: coins)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Spacer(minLength: 0)
            Text(verbatim: "✦").font(.system(size: 26)).foregroundStyle(Palette.goldGradient)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.38))
        .modifier(Shine(period: 5))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Palette.goldGradient, lineWidth: 2.5))
        .shadow(color: Color(hex: 0xFFC83D).opacity(0.35), radius: 10, y: 4)
    }
}

/// Varianta mică, pentru ecranul de loz.
struct CoinPill: View {
    let coins: Int

    var body: some View {
        Text(verbatim: "💰 \(coins)")
            .font(.system(.title2, design: .rounded).weight(.black))
            .foregroundStyle(Palette.goldGradient)
            .contentTransition(.numericText())
            .animation(.snappy, value: coins)
            .padding(.horizontal, 18)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.black.opacity(0.4)))
            .overlay(Capsule().strokeBorder(Palette.goldGradient, lineWidth: 1.5))
    }
}

// MARK: - Dale de acțiune din lobby

struct ActionTile: View {
    let emoji: String
    let title: String
    var subtitle = ""
    let colors: [Color]
    /// Chenar auriu când acțiunea e disponibilă acum.
    var highlighted = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji).font(.system(size: 34)).shadow(color: Color.black.opacity(0.35), radius: 3, y: 2)
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(Color(hex: 0xFFE27A))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 108)
        .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay(alignment: .top) {
            LinearGradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0)], startPoint: .top, endPoint: .bottom)
                .frame(height: 42)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            if highlighted {
                RoundedRectangle(cornerRadius: 20).strokeBorder(Palette.goldGradient, lineWidth: 3)
            } else {
                RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
            }
        }
        .shadow(color: (colors.last ?? .black).opacity(0.5), radius: 6, y: 4)
        .saturation(isEnabled ? 1 : 0.35)
        .opacity(isEnabled ? 1 : 0.8)
    }
}

// MARK: - Cartonașul unui loz în lobby

struct LobbyTicketCard: View {
    let type: TicketType
    var phase: Double = 0

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RotatingBurst().frame(width: 124, height: 124)
                Text(type.emoji).font(.system(size: 58)).shadow(color: Color.black.opacity(0.45), radius: 5, y: 3)
            }
            .frame(height: 86)

            Text(type.title)
                .font(.system(.headline, design: .rounded).weight(.black))
                .foregroundStyle(Color.white)
                .shadow(color: Color.black.opacity(0.5), radius: 2, y: 1)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity, minHeight: 40)

            HStack(spacing: 6) {
                Text(verbatim: "\(type.price) 💰")
                    .foregroundStyle(Color.black.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.92)))
                Text(verbatim: "🏆 \(type.price * type.multiplier(for: .jackpot))")
                    .foregroundStyle(Color(hex: 0xFFE27A))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.45)))
                    .overlay(Capsule().strokeBorder(Palette.goldGradient, lineWidth: 1))
            }
            .font(.system(.caption, design: .rounded).weight(.heavy))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 8)
        .padding(.top, 18)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                type.backgroundGradient
                PatternLayer(symbol: type.style.pattern, opacity: 0.18)
                LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.3)], startPoint: .center, endPoint: .bottom)
            }
        }
        .overlay(alignment: .top) {
            if type.season != nil {
                Text(L("lobby.limited"))
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.yellow))
                    .padding(.top, 5)
            }
        }
        .modifier(Shine(period: 5, phase: phase))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Palette.goldGradient, lineWidth: 2.5))
        .shadow(color: (type.style.background.last ?? .black).opacity(0.55), radius: 8, y: 5)
    }
}

// MARK: - Mesajul de după răzuit

struct ResultBanner: View {
    let text: String
    let isWin: Bool

    var body: some View {
        if text.isEmpty {
            EmptyView()
        } else if isWin {
            Text(text)
                .font(.system(.title3, design: .rounded).weight(.black))
                .foregroundStyle(Color(hex: 0x3A2400))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Palette.goldGradient)
                .modifier(Shine(period: 2.6))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.7), lineWidth: 1.5))
                .shadow(color: Color(hex: 0xFFC83D).opacity(0.7), radius: 12)
        } else {
            Text(text)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.38)))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
        }
    }
}

/// Titlu de secțiune, cu linii aurii de o parte și de alta.
struct SectionTitle: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            line
            Text(verbatim: "✦ " + text.uppercased() + " ✦")
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Palette.goldGradient)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .layoutPriority(1)
            line
        }
    }

    private var line: some View {
        Rectangle().fill(Palette.goldGradient).frame(height: 1.5).opacity(0.7)
    }
}
