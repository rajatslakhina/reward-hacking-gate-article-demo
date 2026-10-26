import SwiftUI
import TaskIntegrity

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(screen: UserDefaults.standard.string(forKey: "screen") == "contract" ? .contract : .attempts)
        }
    }
}

enum Screen: String, CaseIterable, Identifiable {
    case attempts = "10 attempts"
    case contract = "Task contract"
    var id: String { rawValue }
}

struct RootView: View {
    @State var screen: Screen

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Screen", selection: $screen) {
                        ForEach(Screen.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                switch screen {
                case .attempts: AttemptSections()
                case .contract: ContractSections()
                }
                Section {
                    EmptyView()
                } footer: {
                    Text("Constructed example: one bug, one honest fix and nine hand-written ways to fake a green build. Not output from a real agent run.")
                }
            }
            .navigationTitle("Green, but honest?")
        }
    }
}

// MARK: - Attempts

struct AttemptSections: View {
    private let score = SampleScenario.score
    @State private var selected: Int?

    var body: some View {
        Section("Gamed attempts caught, out of \(score.gamedTotal)") {
            HStack(spacing: 8) {
                Tile(value: score.caught(by: .hook), label: "Hook", color: .orange)
                Tile(value: score.caught(by: .audit), label: "Diff audit", color: .blue)
                Tile(value: score.caught(by: .evidence), label: "Evidence", color: .purple)
                Tile(value: score.caughtByAny, label: "All three", color: .green)
            }
            .padding(.vertical, 4)
        }
        Section {
            ForEach(SampleScenario.reports) { report in
                AttemptRow(report: report, expanded: selected == report.id)
                    .contentShape(Rectangle())
                    .onTapGesture { selected = selected == report.id ? nil : report.id }
            }
        } header: {
            HStack {
                Text("Attempt")
                Spacer()
                Text("H · A · E")
            }
        }
    }
}

struct AttemptRow: View {
    let report: AttemptReport
    let expanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text("\(report.attempt.id)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .frame(width: 20)
                    .foregroundStyle(.secondary)
                Text(report.attempt.title)
                    .font(.subheadline.weight(report.attempt.isHonest ? .semibold : .regular))
                    .foregroundStyle(report.attempt.isHonest ? Color.green : Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 4)
                ForEach(Layer.allCases) { layer in
                    Image(systemName: report.caught(by: layer) ? "xmark.octagon.fill" : "circle")
                        .foregroundStyle(report.caught(by: layer) ? color(layer) : Color.secondary.opacity(0.4))
                        .font(.footnote)
                }
            }
            if expanded {
                Text(report.attempt.summary).font(.caption)
                Text(report.headline).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func color(_ layer: Layer) -> Color {
        switch layer {
        case .hook: return .orange
        case .audit: return .blue
        case .evidence: return .purple
        }
    }
}

// MARK: - Contract

struct ContractSections: View {
    private let contract = SampleScenario.contract
    private let only = LayerScore.onlyCaughtBy(SampleScenario.reports)

    var body: some View {
        Section("The brief the agent gets") {
            Text(contract.brief(goal: SampleScenario.goal))
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
        Section("Caught by one layer only") {
            OnlyRow(layer: "Diff audit", ids: only[.audit] ?? [], color: .blue)
            OnlyRow(layer: "Evidence", ids: only[.evidence] ?? [], color: .purple)
            OnlyRow(layer: "Hook", ids: only[.hook] ?? [], color: .orange)
        }
    }
}

struct OnlyRow: View {
    let layer: String
    let ids: [Int]
    let color: Color

    var body: some View {
        HStack {
            Text(layer)
            Spacer()
            Text(ids.isEmpty ? "none" : ids.map { "#\($0)" }.joined(separator: " "))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(ids.isEmpty ? Color.secondary : color)
        }
    }
}

// MARK: - Shared

struct Tile: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }
}
