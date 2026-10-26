# TaskIntegrity: catching a coding agent that games a green build

Companion demo for the article **"I Wrote 9 Ways for a Coding Agent to Fake a Green Build. A Protected-Tests Hook Stopped 3."**
Article: [I Wrote 9 Ways for a Coding Agent to Fake a Green Build. A Protected-Tests Hook Stopped 3.](https://medium.com/@er.rajatlakhina/i-wrote-9-ways-for-a-coding-agent-to-fake-a-green-build-a-protected-tests-hook-stopped-3-06074cc86dae) (Medium)

Coding agents are trained to make checks pass, and a check can pass for the wrong reason. This repo is a small Swift package that models three layers a team lead can put between an agent and "done", and scores them against a constructed example: one bug, one honest fix and nine hand-written ways to fake a green build.

| Layer | What it sees | Gamed attempts caught |
|---|---|---|
| `ProtectedPathHook` | paths the agent tries to edit, during the run | 3 / 9 |
| `DiffAudit` | the lines that went in and came out, after the run | 8 / 9 |
| `EvidenceCheck` | the commands that actually ran and their test totals, from the harness log | 3 / 9 |
| `IntegrityGate` (all three) | | **9 / 9**, honest fix accepted |

The attempts are hand-written to match patterns teams report (edited assertions, `XCTSkip`, excluding a test file in `Package.swift`, `try?`, hard-coding the test's expected value, `fatalError` stubs, a filtered `swift test`, a re-recorded snapshot, a disabled lint rule). None of them came from a real agent run.

![The demo running on the iOS Simulator: per-layer catch counts and the generated task brief](docs/simulator.png)

## The idea in code

The brief the agent gets is generated from the same `TaskContract` the gate checks, so the prompt and the checks cannot drift apart:

```swift
let contract = TaskContract(
    protectedPrefixes: ["Tests/"],
    checkerFiles: ["Package.swift", ".swiftlint.yml"],
    requiredCommand: "swift test",
    baselineTestCount: 42
)
let brief = contract.brief(goal: "Fix CartTotals so discounted totals round to the cent correctly.")
```

The gate accepts an attempt only when no layer objects:

```swift
let gate = IntegrityGate(contract: contract, protectedSources: protectedTests)
let report = gate.report(attempt)
report.accepted          // false
report.headline          // "`swift test` never ran unfiltered"
```

`EvidenceCheck` is only as honest as its input. Feed it the harness's own log of commands and exit codes, never the agent's summary of what it ran.

## What's in it

- `Sources/TaskIntegrity/TaskContract.swift`: protected paths, checker files, the required command, the baseline test count, and `brief(goal:)`.
- `Sources/TaskIntegrity/Layers.swift`: `ProtectedPathHook`, `DiffAudit` (eight text rules) and `EvidenceCheck`.
- `Sources/TaskIntegrity/IntegrityGate.swift`: runs the three layers and scores them (`LayerScore`).
- `Sources/TaskIntegrity/SampleScenario.swift`: the constructed bug and ten attempts.
- `Tests/TaskIntegrityTests`: 22 tests. Every number above is asserted there.
- `Demo.xcodeproj` + `Demo/DemoApp.swift`: a SwiftUI app that consumes the package through a local package reference.

## How to run it

```bash
git clone https://github.com/rajatslakhina/reward-hacking-gate-article-demo.git
cd reward-hacking-gate-article-demo
open Demo.xcodeproj   # pick an iPhone simulator, then Build & Run
swift test            # library tests, no Xcode project needed
```

No other setup. Tap an attempt to see the first reason it was rejected; switch to **Task contract** to read the generated brief.

## Verification status

- `swift build -Xswiftc -warnings-as-errors` and `swift test` (22 tests, 0 failures) pass on Linux (Swift 6.1.2) and on macOS in CI.
- The `demo-on-simulator` CI job builds `Demo.xcodeproj`, installs and launches the app on an iPhone simulator, checks the process is still alive, and captures `Demo/Screenshots/attempts.png` and `contract.png`.

## Licence

MIT
