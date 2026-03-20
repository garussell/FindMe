import Foundation

struct AppConfiguration: Sendable {
    let adzunaAppID: String?
    let adzunaAppKey: String?
    let jsearchAPIKey: String?
    let usaJobsAPIKey: String?
    let usaJobsUserAgent: String?
    let blsAPIKey: String?
    let serpApiKey: String?

    init(bundle: Bundle = .main, environment: [String: String] = ProcessInfo.processInfo.environment) {
        let localPlistValues = (bundle.url(forResource: "APIConfig.local", withExtension: "plist"))
            .flatMap { NSDictionary(contentsOf: $0) as? [String: Any] } ?? [:]
        let plistValues = (bundle.url(forResource: "APIConfig", withExtension: "plist"))
            .flatMap { NSDictionary(contentsOf: $0) as? [String: Any] } ?? [:]

        func resolvedValue(for key: String) -> String? {
            if let envValue = environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !envValue.isEmpty {
                return envValue
            }

            if let localPlistValue = (localPlistValues[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !localPlistValue.isEmpty {
                return localPlistValue
            }

            if let plistValue = (plistValues[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !plistValue.isEmpty {
                return plistValue
            }

            return nil
        }

        adzunaAppID = resolvedValue(for: "ADZUNA_APP_ID")
        adzunaAppKey = resolvedValue(for: "ADZUNA_APP_KEY")
        jsearchAPIKey = resolvedValue(for: "JSEARCH_API_KEY")
        usaJobsAPIKey = resolvedValue(for: "USAJOBS_API_KEY")
        usaJobsUserAgent = resolvedValue(for: "USAJOBS_USER_AGENT")
        blsAPIKey = resolvedValue(for: "BLS_API_KEY")
        serpApiKey = resolvedValue(for: "SERPAPI_KEY")
    }

    var hasAdzunaCredentials: Bool {
        adzunaAppID != nil && adzunaAppKey != nil
    }

    var hasJSearchCredentials: Bool {
        jsearchAPIKey != nil
    }

    var hasUSAJobsCredentials: Bool {
        usaJobsAPIKey != nil && usaJobsUserAgent != nil
    }

    var hasSerpApiCredentials: Bool {
        serpApiKey != nil
    }
}
