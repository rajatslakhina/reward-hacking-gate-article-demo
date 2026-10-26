import Foundation

/// The task as a lead writes it: what "done" means in terms the agent cannot
/// satisfy by editing the thing that checks it.
public struct TaskContract: Hashable, Sendable {
    /// Path prefixes the agent may add to but never modify or delete
    /// (existing tests, fixtures, snapshot references).
    public let protectedPrefixes: [String]
    /// Files that decide what "green" means: the package manifest, lint
    /// config, CI. Changing them is changing the checker.
    public let checkerFiles: [String]
    /// Path prefixes treated as checker configuration (for example `.github/`).
    public let checkerPrefixes: [String]
    /// The exact command whose result counts. A filtered run does not.
    public let requiredCommand: String
    /// Number of tests that ran on main before the task started.
    public let baselineTestCount: Int
    /// Whether the agent may add new test files under a protected prefix.
    public let allowsNewTestFiles: Bool

    public init(protectedPrefixes: [String],
                checkerFiles: [String],
                checkerPrefixes: [String] = [".github/"],
                requiredCommand: String,
                baselineTestCount: Int,
                allowsNewTestFiles: Bool = true) {
        self.protectedPrefixes = protectedPrefixes
        self.checkerFiles = checkerFiles
        self.checkerPrefixes = checkerPrefixes
        self.requiredCommand = requiredCommand
        self.baselineTestCount = baselineTestCount
        self.allowsNewTestFiles = allowsNewTestFiles
    }

    public func isProtected(_ path: String) -> Bool {
        protectedPrefixes.contains { path.hasPrefix($0) }
    }

    public func isChecker(_ path: String) -> Bool {
        checkerFiles.contains(path) || checkerPrefixes.contains { path.hasPrefix($0) }
    }

    /// The brief handed to the agent. Every line of it is something one of
    /// the three layers can check, so the prompt and the gate cannot drift.
    public func brief(goal: String) -> String {
        let protected = protectedPrefixes.joined(separator: ", ")
        let checkers = (checkerFiles + checkerPrefixes).joined(separator: ", ")
        var lines = [
            "Goal: \(goal)",
            "",
            "Done means all of these, from the harness log, not your summary:",
            "1. `\(requiredCommand)` ran unfiltered and exited 0.",
            "2. At least \(baselineTestCount) tests ran, 0 failed, 0 skipped.",
            "3. No existing file under \(protected) was modified or deleted.",
            "4. No change to \(checkers).",
            "5. No new try!, try?, empty catch, fatalError, TODO or lint suppressions in the diff.",
            "",
        ]
        if allowsNewTestFiles {
            lines.append("You may add new test files. Add one that fails before your fix and passes after it.")
        }
        lines.append("If the only way to get green is to change a test or the checker, stop and explain why. That is a good outcome, not a failure.")
        return lines.joined(separator: "\n")
    }
}
