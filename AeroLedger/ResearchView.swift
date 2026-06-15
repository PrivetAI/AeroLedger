import SwiftUI

struct ResearchView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        ScreenScaffold("Research Lab") {
            TopHUD()

            if let rip = store.state.researchInProgress, let def = ResearchCatalog.node(rip.nodeID) {
                Panel {
                    SectionHeader(text: "In Progress")
                    Text(def.name).font(.system(size: 16, weight: .bold)).foregroundColor(Brand.jet)
                    Text(def.desc).font(.system(size: 12)).foregroundColor(Brand.muted)
                    BarView(value: Double(rip.weeksDone) / Double(def.weeks), color: Brand.amber)
                    Text("\(rip.weeksDone) / \(def.weeks) weeks").font(.system(size: 11, design: .monospaced)).foregroundColor(Brand.faint)
                }
            }

            Text("Research unlocks larger aircraft, fuel tech, premium services, marketing and automation. Each node needs cash and prerequisite nodes.")
                .font(.system(size: 12)).foregroundColor(Brand.faint).lineSpacing(3)

            // Display as tiers/columns
            ForEach(0...5, id: \.self) { col in
                let nodes = ResearchCatalog.nodes.filter { $0.col == col }.sorted { $0.row < $1.row }
                if !nodes.isEmpty {
                    SectionHeader(text: "Tier \(col + 1)")
                    ForEach(nodes) { node in
                        nodeCard(node)
                    }
                }
            }
        }
    }

    private func nodeCard(_ node: ResearchNodeDef) -> some View {
        let done = store.state.completedResearch.contains(node.id)
        let prereqMet = node.prereqs.allSatisfy { store.state.completedResearch.contains($0) }
        let inProgress = store.state.researchInProgress?.nodeID == node.id
        let canStart = store.canStartResearch(node)
        return Panel {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Brand.navyDeep).frame(width: 40, height: 40)
                    if done {
                        StrokedIcon(shape: CheckIcon(), color: Brand.green, size: 22, line: 2.5)
                    } else {
                        StrokedIcon(shape: FlaskIcon(), color: prereqMet ? Brand.sky : Brand.faint, size: 22, line: 2)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.name).font(.system(size: 15, weight: .bold)).foregroundColor(Brand.jet)
                    Text(node.desc).font(.system(size: 11)).foregroundColor(Brand.muted)
                }
                Spacer()
            }
            if !node.prereqs.isEmpty {
                Text("Requires: " + node.prereqs.compactMap { ResearchCatalog.node($0)?.name }.joined(separator: ", "))
                    .font(.system(size: 10)).foregroundColor(prereqMet ? Brand.faint : Brand.amber)
            }
            HStack {
                Text(Fmt.money(node.cost)).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundColor(Brand.sky)
                Text("• \(node.weeks) wk").font(.system(size: 12)).foregroundColor(Brand.faint)
                Spacer()
                if done {
                    Text("DONE").font(.system(size: 12, weight: .heavy)).foregroundColor(Brand.green)
                } else if inProgress {
                    Text("RESEARCHING").font(.system(size: 12, weight: .bold)).foregroundColor(Brand.amber)
                } else {
                    Button(action: { store.startResearch(node) }) {
                        Text("Start").font(.system(size: 13, weight: .bold)).foregroundColor(canStart ? Brand.navyDeep : Brand.faint)
                            .padding(.horizontal, 20).padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 9).fill(canStart ? Brand.sky : Brand.card))
                    }.buttonStyle(.plain).disabled(!canStart)
                }
            }
        }
    }
}
