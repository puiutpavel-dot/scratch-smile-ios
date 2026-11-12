import SwiftUI
import UIKit

/// Pagina aplicației din App Store (devine activă după publicare).
let appStoreURL = "https://apps.apple.com/app/id6833610079"

// MARK: - Rețelele pentru care se acordă bonusul

enum SocialNetwork: String, CaseIterable, Identifiable {
    case facebook, instagram, tiktok, x, whatsapp, telegram, messenger, snapchat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .facebook: return "Facebook"
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        case .x: return "X"
        case .whatsapp: return "WhatsApp"
        case .telegram: return "Telegram"
        case .messenger: return "Messenger"
        case .snapchat: return "Snapchat"
        }
    }

    /// Fragmente din identificatorul extensiei de share a fiecărei aplicații (cu litere mici).
    private var markers: [String] {
        switch self {
        case .messenger: return ["messenger"]
        case .facebook: return ["facebook"]
        case .instagram: return ["instagram", "burbn"]
        case .tiktok: return ["tiktok", "musically"]
        case .x: return ["twitter", "tweetie"]
        case .whatsapp: return ["whatsapp"]
        case .telegram: return ["telegra"]
        case .snapchat: return ["snapchat", "picaboo"]
        }
    }

    /// Rețeaua aleasă în fereastra de share, dacă e una dintre cele premiate.
    static func from(activityType: UIActivity.ActivityType?) -> SocialNetwork? {
        guard let raw = activityType?.rawValue.lowercased() else { return nil }
        // Messenger înaintea Facebook: identificatorul lui conține ambele cuvinte.
        let order: [SocialNetwork] = [.messenger, .facebook, .instagram, .tiktok, .x, .whatsapp, .telegram, .snapchat]
        return order.first { network in network.markers.contains { raw.contains($0) } }
    }
}

// MARK: - Bonusul de share

enum ShareRewards {
    /// Monede primite pentru fiecare rețea, o singură dată.
    static let amount = 10_000
    static var amountText: String { amount.formatted() }

    private static let store = UserDefaults.standard
    private static let key = "shareRewarded"        // de forma "facebook,whatsapp"

    static func rewarded(in stored: String) -> Set<String> {
        Set(stored.split(separator: ",").map(String.init))
    }

    /// Apelat când se închide fereastra de share. Întoarce rețeaua premiată acum, dacă e cazul.
    @discardableResult
    static func handle(activityType: UIActivity.ActivityType?, completed: Bool) -> SocialNetwork? {
        guard completed, let network = SocialNetwork.from(activityType: activityType) else { return nil }
        var done = rewarded(in: store.string(forKey: key) ?? "")
        guard !done.contains(network.rawValue) else { return nil }
        done.insert(network.rawValue)
        store.set(done.sorted().joined(separator: ","), forKey: key)

        let coins = store.object(forKey: "coins") as? Int ?? 1500     // 1500 = soldul de pornire
        store.set(coins + amount, forKey: "coins")
        if Feedback.soundOn { Feedback.win() }
        return network
    }
}

// MARK: - Fereastra de share a sistemului, cu rezultat

struct ActivitySheet: UIViewControllerRepresentable {
    let items: [Any]
    let onFinish: (UIActivity.ActivityType?, Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { activityType, completed, _, _ in
            onFinish(activityType, completed)
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// MARK: - Ecranul „Distribuie și câștigă”

struct ShareBonusScreen: View {
    @AppStorage("shareRewarded") private var stored = ""
    @AppStorage("coins") private var coins = 1500
    @State private var showSheet = false
    @State private var notice = ""

    var body: some View {
        let done = ShareRewards.rewarded(in: stored)

        List {
            Section {
                Text(verbatim: "💰 \(coins)").font(.title2.bold())
                Text(L("share.bonus.info", ShareRewards.amountText))
                Button {
                    showSheet = true
                } label: {
                    Label(L("share.bonus.button"), systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                if !notice.isEmpty {
                    Text(notice).font(.headline).multilineTextAlignment(.center)
                }
            }

            Section {
                ForEach(SocialNetwork.allCases) { network in
                    HStack {
                        Text(network.title).font(.headline)
                        Spacer()
                        if done.contains(network.rawValue) {
                            Text(verbatim: "✅ " + L("share.bonus.done")).foregroundStyle(.secondary)
                        } else {
                            Text(verbatim: "+\(ShareRewards.amountText) 💰").bold()
                        }
                    }
                }
            }
        }
        .navigationTitle(L("share.bonus.title"))
        .sheet(isPresented: $showSheet) {
            ActivitySheet(items: shareItems) { activityType, completed in
                showSheet = false
                guard completed else { return }
                if let network = ShareRewards.handle(activityType: activityType, completed: completed) {
                    notice = L("share.bonus.got", ShareRewards.amountText, network.title)
                } else {
                    notice = L("share.bonus.none")
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var shareItems: [Any] {
        var items: [Any] = [L("share.bonus.text", appName)]
        if let url = URL(string: appStoreURL) { items.append(url) }
        return items
    }
}
