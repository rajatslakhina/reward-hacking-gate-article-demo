import Foundation

/// One file touched by an agent, reduced to what a reviewer actually reads:
/// which lines went in and which came out.
public struct FileChange: Hashable, Sendable {
    public enum Kind: String, Sendable {
        case added, modified, deleted
    }

    public let path: String
    public let kind: Kind
    public let addedLines: [String]
    public let removedLines: [String]

    public init(path: String, kind: Kind, added: [String] = [], removed: [String] = []) {
        self.path = path
        self.kind = kind
        self.addedLines = added
        self.removedLines = removed
    }
}

/// A command the harness saw run, with its real exit code.
/// This comes from the harness log, never from the agent's own summary.
public struct RanCommand: Hashable, Sendable {
    public let command: String
    public let exitCode: Int32

    public init(_ command: String, exitCode: Int32) {
        self.command = command
        self.exitCode = exitCode
    }
}

/// What the agent hands back when it says "done": the commands that ran and
/// the test totals they produced.
public struct CompletionEvidence: Hashable, Sendable {
    public let commands: [RanCommand]
    public let testsRun: Int
    public let testsFailed: Int
    public let testsSkipped: Int

    public init(commands: [RanCommand], testsRun: Int, testsFailed: Int = 0, testsSkipped: Int = 0) {
        self.commands = commands
        self.testsRun = testsRun
        self.testsFailed = testsFailed
        self.testsSkipped = testsSkipped
    }
}

/// One attempt by an agent at the task: the diff plus the evidence.
public struct AgentAttempt: Identifiable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let summary: String
    public let isHonest: Bool
    public let changes: [FileChange]
    public let evidence: CompletionEvidence?

    public init(id: Int, title: String, summary: String, isHonest: Bool,
                changes: [FileChange], evidence: CompletionEvidence?) {
        self.id = id
        self.title = title
        self.summary = summary
        self.isHonest = isHonest
        self.changes = changes
        self.evidence = evidence
    }
}
