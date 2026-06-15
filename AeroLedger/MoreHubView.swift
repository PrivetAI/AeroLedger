import SwiftUI

struct MoreHubView: View {
    @EnvironmentObject var store: GameStore
    let onExitToMenu: () -> Void

    var body: some View {
        ScreenScaffold("More") {
            TopHUD()
            Panel {
                navRow("Contracts", "\(store.state.completedContracts.count)/\(ContractCatalog.contracts.count)", TrophyIcon(), AnyView(ContractsView()))
                Divider().background(Brand.stroke)
                navRow("Achievements", "\(store.state.unlockedAchievements.count)/\(AchievementCatalog.achievements.count)", CheckIcon(), AnyView(AchievementsView()))
                Divider().background(Brand.stroke)
                navRow("Prestige Ranks", PrestigeCatalog.ranks[store.state.rankIndex].name, TowerShape(), AnyView(PrestigeView()))
                Divider().background(Brand.stroke)
                navRow("Statistics", "", ChartIcon(), AnyView(StatisticsView()))
                Divider().background(Brand.stroke)
                navRow("Guide", "", FlaskIcon(), AnyView(GuideView()))
                Divider().background(Brand.stroke)
                navRow("Settings", "", MenuDotsIcon(), AnyView(SettingsView(onExitToMenu: onExitToMenu)))
            }
        }
    }

    private func navRow(_ title: String, _ value: String, _ shape: some Shape, _ dest: AnyView) -> some View {
        NavigationLink(destination: dest) {
            HStack(spacing: 12) {
                StrokedIcon(shape: shape, color: Brand.sky, size: 20, line: 2)
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.jet)
                Spacer()
                if !value.isEmpty {
                    Text(value).font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(Brand.muted)
                }
                StrokedIcon(shape: ChevronIcon(), color: Brand.faint, size: 13, line: 2)
            }
            .padding(.vertical, 6)
        }.buttonStyle(.plain)
    }
}

// MARK: - Contracts
struct ContractsView: View {
    @EnvironmentObject var store: GameStore
    var body: some View {
        ScreenScaffold("Contracts") {
            Text("Complete milestones to earn cash rewards.").font(.system(size: 12)).foregroundColor(Brand.faint)
            ForEach(ContractCatalog.contracts) { c in
                let done = store.state.completedContracts.contains(c.id)
                let cur = GameEngine.metricValue(c.metric, store.state)
                Panel {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(Brand.navyDeep).frame(width: 38, height: 38)
                            if done { StrokedIcon(shape: CheckIcon(), color: Brand.green, size: 20, line: 2.5) }
                            else { StrokedIcon(shape: TrophyIcon(), color: Brand.amber, size: 20, line: 2) }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.title).font(.system(size: 15, weight: .bold)).foregroundColor(Brand.jet)
                            Text(c.detail).font(.system(size: 11)).foregroundColor(Brand.muted)
                        }
                        Spacer()
                        Text("+" + Fmt.money(c.reward)).font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(done ? Brand.green : Brand.faint)
                    }
                    if !done {
                        BarView(value: cur / c.target, color: Brand.amber, height: 6)
                        Text("\(fmtMetric(c.metric, cur)) / \(fmtMetric(c.metric, c.target))")
                            .font(.system(size: 10, design: .monospaced)).foregroundColor(Brand.faint)
                    }
                }
            }
        }
    }
}

// MARK: - Achievements
struct AchievementsView: View {
    @EnvironmentObject var store: GameStore
    var body: some View {
        ScreenScaffold("Achievements") {
            let unlocked = store.state.unlockedAchievements.count
            Panel {
                HStack {
                    Text("Unlocked").font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.muted)
                    Spacer()
                    Text("\(unlocked) / \(AchievementCatalog.achievements.count)").font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(Brand.sky)
                }
                BarView(value: Double(unlocked) / Double(AchievementCatalog.achievements.count), color: Brand.green)
            }
            let cols = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(AchievementCatalog.achievements) { a in
                    let done = store.state.unlockedAchievements.contains(a.id)
                    VStack(spacing: 6) {
                        StrokedIcon(shape: TrophyIcon(), color: done ? Brand.amber : Brand.stroke, size: 28, line: 2)
                        Text(a.title).font(.system(size: 12, weight: .bold)).foregroundColor(done ? Brand.jet : Brand.faint)
                            .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
                        Text(a.desc).font(.system(size: 9)).foregroundColor(Brand.faint)
                            .multilineTextAlignment(.center).lineLimit(3)
                    }
                    .frame(maxWidth: .infinity, minHeight: 110)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(done ? Brand.card : Brand.navyDeep))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(done ? Brand.amber.opacity(0.4) : Brand.stroke, lineWidth: 1))
                }
            }
        }
    }
}

// MARK: - Prestige
struct PrestigeView: View {
    @EnvironmentObject var store: GameStore
    var body: some View {
        ScreenScaffold("Prestige Ranks") {
            Panel {
                Text("Current Standing").font(.system(size: 12, weight: .bold)).foregroundColor(Brand.faint)
                Text(PrestigeCatalog.ranks[store.state.rankIndex].name).font(.system(size: 20, weight: .heavy)).foregroundColor(Brand.jet)
                Text("\(Fmt.int(Int(store.state.prestige))) prestige points").font(.system(size: 13, design: .monospaced)).foregroundColor(Brand.sky)
            }
            ForEach(0..<PrestigeCatalog.ranks.count, id: \.self) { i in
                let rank = PrestigeCatalog.ranks[i]
                let reached = store.state.rankIndex >= i
                Panel {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(reached ? Brand.sky.opacity(0.2) : Brand.navyDeep).frame(width: 40, height: 40)
                            Text("\(i + 1)").font(.system(size: 16, weight: .heavy)).foregroundColor(reached ? Brand.sky : Brand.faint)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rank.name).font(.system(size: 15, weight: .bold)).foregroundColor(reached ? Brand.jet : Brand.muted)
                            Text("\(Fmt.int(Int(rank.threshold))) pts").font(.system(size: 11, design: .monospaced)).foregroundColor(Brand.faint)
                        }
                        Spacer()
                        if reached { StrokedIcon(shape: CheckIcon(), color: Brand.green, size: 18, line: 2.5) }
                    }
                }
            }
        }
    }
}

func fmtMetric(_ m: ContractMetric, _ v: Double) -> String {
    switch m {
    case .satisfaction: return Fmt.pct(v)
    case .cash, .cargoRevenue, .loungeRevenue, .weeklyRevenue, .totalProfit: return Fmt.money(v)
    case .prestige: return PrestigeCatalog.ranks[min(PrestigeCatalog.ranks.count - 1, max(0, Int(v)))].name
    default: return Fmt.int(Int(v))
    }
}
