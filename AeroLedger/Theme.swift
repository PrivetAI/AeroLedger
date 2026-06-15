import SwiftUI

// MARK: - Brand / Design System
// Clean aviation dashboard: deep navy + sky blue + jet white + signal colors.
enum Brand {
    static let navy = Color(red: 0.05, green: 0.09, blue: 0.18)          // background deep navy
    static let navyDeep = Color(red: 0.03, green: 0.06, blue: 0.13)      // darker panels
    static let card = Color(red: 0.09, green: 0.14, blue: 0.25)          // card surface
    static let cardRaised = Color(red: 0.12, green: 0.18, blue: 0.31)    // raised surface
    static let sky = Color(red: 0.30, green: 0.62, blue: 0.95)           // sky blue accent
    static let skyDim = Color(red: 0.22, green: 0.45, blue: 0.72)        // dimmed sky
    static let jet = Color(red: 0.95, green: 0.97, blue: 1.0)            // jet white text
    static let muted = Color(red: 0.62, green: 0.70, blue: 0.84)         // muted text
    static let faint = Color(red: 0.40, green: 0.48, blue: 0.62)         // faint text

    static let amber = Color(red: 1.0, green: 0.74, blue: 0.22)          // signal amber
    static let green = Color(red: 0.30, green: 0.84, blue: 0.55)         // positive
    static let red = Color(red: 0.96, green: 0.39, blue: 0.42)           // negative

    static let stroke = Color(red: 0.20, green: 0.28, blue: 0.42)        // hairline

    // Class tint
    static func classColor(_ c: TravelClass) -> Color {
        switch c {
        case .economy: return sky
        case .business: return amber
        case .first: return green
        }
    }

    // Rarity tint
    static func rarityColor(_ r: Rarity) -> Color {
        switch r {
        case .rookie: return muted
        case .pro: return sky
        case .veteran: return amber
        }
    }
}

// MARK: - Number formatting
enum Fmt {
    /// Abbreviated number with K/M/B/T. Integers under 1000 print plain.
    static func abbr(_ value: Double) -> String {
        let v = value
        let neg = v < 0
        let a = abs(v)
        let s: String
        if a < 1_000 {
            s = String(Int(a.rounded()))
        } else if a < 1_000_000 {
            s = trim(a / 1_000) + "K"
        } else if a < 1_000_000_000 {
            s = trim(a / 1_000_000) + "M"
        } else if a < 1_000_000_000_000 {
            s = trim(a / 1_000_000_000) + "B"
        } else {
            s = trim(a / 1_000_000_000_000) + "T"
        }
        return neg ? "-" + s : s
    }

    private static func trim(_ x: Double) -> String {
        if x >= 100 { return String(Int(x.rounded())) }
        // one decimal
        let r = (x * 10).rounded() / 10
        if r == r.rounded() { return String(Int(r)) }
        return String(format: "%.1f", r)
    }

    static func money(_ value: Double) -> String { "$" + abbr(value) }

    static func moneySigned(_ value: Double) -> String {
        (value >= 0 ? "+$" : "-$") + abbr(abs(value))
    }

    static func pct(_ frac: Double) -> String {
        String(Int((frac * 100).rounded())) + "%"
    }

    static func int(_ value: Int) -> String { abbr(Double(value)) }
}

// MARK: - Reusable view styling
struct CardBackground: ViewModifier {
    var raised: Bool = false
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(raised ? Brand.cardRaised : Brand.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Brand.stroke, lineWidth: 1)
            )
    }
}

extension View {
    func card(raised: Bool = false) -> some View { modifier(CardBackground(raised: raised)) }
    func monoDigits() -> some View { self.font(.system(.body, design: .monospaced)) }
}

// Primary action button
struct PrimaryButton: View {
    let title: String
    var enabled: Bool = true
    var color: Color = Brand.sky
    let action: () -> Void
    var body: some View {
        Button(action: { if enabled { action() } }) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(enabled ? Brand.navyDeep : Brand.faint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(enabled ? color : Brand.card)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct GhostButton: View {
    let title: String
    var color: Color = Brand.sky
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(color.opacity(0.6), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// Section header
struct SectionHeader: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold))
            .tracking(1.2)
            .foregroundColor(Brand.faint)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Stat chip
struct StatChip: View {
    let label: String
    let value: String
    var tint: Color = Brand.jet
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(Brand.faint)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Brand.navyDeep)
        )
    }
}
