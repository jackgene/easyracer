import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(FoundationNetworking)
typealias FoundationURLSession = FoundationNetworking.URLSession
#else
typealias FoundationURLSession = Foundation.URLSession
#endif

/// URLSession operations we actually use in Easy Racer
protocol URLSession: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

/// Make sure the URLSession protocol isn't defining incompatible methods
extension FoundationURLSession: URLSession {
#if canImport(FoundationNetworking)
    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await withUnsafeThrowingContinuation { continuation in
            dataTask(with: url) { data, response, error in
                if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError()
                }
            }
        }
    }
#endif
}

/// URLSession implementation that is able to handle 10k concurrent connections
///
///  It does this by delegating to Foundation.URLSession, ensuring:
///   - Each delegatee handles no more than requestsPerSession requests
///   - Requests are at least timeIntervalBetweenRequests apart
///     (Needed in some environments, e.g., GitHub Actions)
actor ScalableURLSession: URLSession {
    private static let nanosecondsPerSecond: Double = 1_000_000_000
    
    private let configuration: URLSessionConfiguration
    private let requestsPerSession: UInt
    private let timeIntervalBetweenRequests: TimeInterval
    
    private var currentDelegatee: FoundationURLSession
    private var currentRequestCount: UInt = 0
    private var nextRequestNotBefore: Date = .distantPast
    private var delegatee: FoundationURLSession {
        get {
            if currentRequestCount < requestsPerSession {
                currentRequestCount += 1
                return currentDelegatee
            } else {
                currentDelegatee.finishTasksAndInvalidate()
                currentDelegatee = FoundationURLSession(configuration: configuration)
                currentRequestCount = 0
                
                return currentDelegatee
            }
        }
    }
    
    init(
        configuration: URLSessionConfiguration,
        requestsPerSession: UInt = 100,
        timeIntervalBetweenRequests: TimeInterval = 0.001
    ) {
        self.configuration = configuration
        self.requestsPerSession = requestsPerSession
        self.timeIntervalBetweenRequests = timeIntervalBetweenRequests
        self.currentDelegatee = FoundationURLSession(
            configuration: configuration
        )
    }
    
    func data(from url: URL) async throws -> (Data, URLResponse) {
        let delay: TimeInterval = nextRequestNotBefore.timeIntervalSinceNow
        if delay > 0 {
            nextRequestNotBefore = nextRequestNotBefore
                .addingTimeInterval(timeIntervalBetweenRequests)
            try await Task.sleep(
                nanoseconds: UInt64(delay * Self.nanosecondsPerSecond)
            )
        } else {
            nextRequestNotBefore = Date()
                .addingTimeInterval(timeIntervalBetweenRequests)
        }
        
        return try await delegatee.data(from: url)
    }
}
