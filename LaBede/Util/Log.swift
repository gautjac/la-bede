import OSLog

/// Centralised loggers, one per concern, so the Console reads cleanly.
enum Log {
    static let intel = Logger(subsystem: "com.jac.LaBede", category: "intelligence")
    static let render = Logger(subsystem: "com.jac.LaBede", category: "render")
    static let store = Logger(subsystem: "com.jac.LaBede", category: "store")
}
