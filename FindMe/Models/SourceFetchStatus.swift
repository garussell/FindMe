import Foundation

struct SourceFetchStatus: Identifiable, Hashable, Sendable {
    enum State: String, Sendable {
        case live
        case sample
        case empty
    }

    let source: JobSource
    let state: State
    let resultCount: Int
    let message: String?

    var id: JobSource { source }
}
