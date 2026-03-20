import Foundation
import Testing
@testable import FindMe

// MARK: - Fixture: Realistic SerpApi Response JSON

/// Realistic SerpApi Google Jobs response fixture with 3 job listings.
/// Used by all tests — no real API calls are ever made.
private let serpApiFixtureJSON = """
{
  "jobs_results": [
    {
      "title": "Senior iOS Engineer",
      "company_name": "Acme Corp",
      "location": "San Francisco, CA",
      "via": "via LinkedIn",
      "description": "Build and ship world-class iOS applications using SwiftUI and Swift Concurrency. Collaborate with designers and backend engineers to deliver features that delight millions of users.",
      "job_id": "serp-job-001",
      "extensions": ["2 days ago", "Full-time", "$150K\\u2013$200K a year", "Health insurance"],
      "detected_extensions": {
        "posted_at": "2 days ago",
        "schedule_type": "Full-time",
        "salary": "$150K\\u2013$200K a year"
      },
      "apply_options": [
        {
          "title": "Acme Careers",
          "link": "https://careers.acme.com/ios-engineer",
          "is_direct": true
        },
        {
          "title": "LinkedIn",
          "link": "https://linkedin.com/jobs/view/12345"
        }
      ]
    },
    {
      "title": "React Developer",
      "company_name": "Widget Inc",
      "location": "Anywhere (Remote)",
      "via": "via Indeed",
      "description": "Join our fully remote team building the next generation of web applications.",
      "job_id": "serp-job-002",
      "extensions": ["1 week ago", "Full-time", "Remote"],
      "detected_extensions": {
        "posted_at": "1 week ago",
        "schedule_type": "Full-time"
      },
      "apply_options": [
        {
          "title": "Indeed",
          "link": "https://indeed.com/viewjob?jk=abc123"
        }
      ]
    },
    {
      "title": "Data Analyst",
      "company_name": "Numbers Co",
      "location": "Austin, TX",
      "via": "via Glassdoor",
      "description": "Analyze large datasets and build dashboards. SQL and Python required.",
      "job_id": "serp-job-003",
      "extensions": ["3 hours ago", "Part-time", "$30\\u2013$45 an hour"],
      "detected_extensions": {
        "posted_at": "3 hours ago",
        "schedule_type": "Part-time",
        "salary": "$30\\u2013$45 an hour"
      },
      "apply_options": []
    }
  ]
}
"""

private let emptyResultsJSON = """
{
  "jobs_results": []
}
"""

private let apiErrorJSON = """
{
  "error": "Your API key is invalid or has been revoked."
}
"""

private let noJobsResultsKeyJSON = """
{
  "search_metadata": {
    "status": "Success"
  }
}
"""

// MARK: - Tests

struct SerpApiResponseDecodingTests {

    @Test func decodesFullResponseWithThreeJobs() throws {
        let data = Data(serpApiFixtureJSON.utf8)
        let response = try JSONDecoder().decode(SerpApiResponse.self, from: data)
        let jobs = try #require(response.jobsResults)

        #expect(jobs.count == 3)
        #expect(response.error == nil)
    }

    @Test func firstJobHasCorrectFields() throws {
        let data = Data(serpApiFixtureJSON.utf8)
        let response = try JSONDecoder().decode(SerpApiResponse.self, from: data)
        let first = try #require(response.jobsResults?.first)

        #expect(first.title == "Senior iOS Engineer")
        #expect(first.companyName == "Acme Corp")
        #expect(first.location == "San Francisco, CA")
        #expect(first.jobId == "serp-job-001")
        #expect(first.detectedExtensions?.scheduleType == "Full-time")
        #expect(first.detectedExtensions?.salary == "$150K\u{2013}$200K a year")
        #expect(first.detectedExtensions?.postedAt == "2 days ago")
    }

    @Test func applyOptionsDecodesDirectLinks() throws {
        let data = Data(serpApiFixtureJSON.utf8)
        let response = try JSONDecoder().decode(SerpApiResponse.self, from: data)
        let first = try #require(response.jobsResults?.first)
        let applyOptions = try #require(first.applyOptions)

        #expect(applyOptions.count == 2)
        #expect(applyOptions[0].isDirect == true)
        #expect(applyOptions[0].link == "https://careers.acme.com/ios-engineer")
    }

    @Test func decodesEmptyJobsResultsArray() throws {
        let data = Data(emptyResultsJSON.utf8)
        let response = try JSONDecoder().decode(SerpApiResponse.self, from: data)

        #expect(response.jobsResults?.isEmpty == true)
        #expect(response.error == nil)
    }

    @Test func decodesAPIError() throws {
        let data = Data(apiErrorJSON.utf8)
        let response = try JSONDecoder().decode(SerpApiResponse.self, from: data)

        #expect(response.error == "Your API key is invalid or has been revoked.")
        #expect(response.jobsResults == nil)
    }

    @Test func decodesResponseWithoutJobsResultsKey() throws {
        let data = Data(noJobsResultsKeyJSON.utf8)
        let response = try JSONDecoder().decode(SerpApiResponse.self, from: data)

        #expect(response.jobsResults == nil)
        #expect(response.error == nil)
    }
}

struct SerpApiCacheTests {

    @Test func cacheReturnsCachedResponseOnSecondCall() async throws {
        let cache = SerpApiCache(ttl: 600)
        let data = Data(serpApiFixtureJSON.utf8)
        let response = try JSONDecoder().decode(SerpApiResponse.self, from: data)
        let key = SerpApiCache.cacheKey(keyword: "iOS", location: "San Francisco")

        // First call: cache miss
        let miss = await cache.get(key: key)
        #expect(miss == nil)

        // Store in cache
        await cache.set(key: key, response: response)

        // Second call: cache hit
        let hit = await cache.get(key: key)
        #expect(hit != nil)
        #expect(hit?.jobsResults?.count == 3)
    }

    @Test func cacheReturnsNilAfterTTLExpires() async throws {
        let cache = SerpApiCache(ttl: 600)
        let data = Data(serpApiFixtureJSON.utf8)
        let response = try JSONDecoder().decode(SerpApiResponse.self, from: data)
        let key = "ios|san francisco"

        // Store with a timestamp in the past (11 minutes ago)
        let pastTime = Date.now.addingTimeInterval(-660)
        await cache.set(key: key, response: response, now: pastTime)

        // Should be expired when checking with current time
        let result = await cache.get(key: key, now: .now)
        #expect(result == nil)
    }

    @Test func cacheReturnsEntryBeforeTTLExpires() async throws {
        let cache = SerpApiCache(ttl: 600)
        let data = Data(serpApiFixtureJSON.utf8)
        let response = try JSONDecoder().decode(SerpApiResponse.self, from: data)
        let key = "ios|san francisco"

        // Store with a timestamp 5 minutes ago (within TTL)
        let recentTime = Date.now.addingTimeInterval(-300)
        await cache.set(key: key, response: response, now: recentTime)

        // Should still be valid
        let result = await cache.get(key: key, now: .now)
        #expect(result != nil)
    }

    @Test func clearCacheRemovesAllEntries() async throws {
        let cache = SerpApiCache(ttl: 600)
        let data = Data(serpApiFixtureJSON.utf8)
        let response = try JSONDecoder().decode(SerpApiResponse.self, from: data)

        await cache.set(key: "a", response: response)
        await cache.set(key: "b", response: response)

        await cache.clearCache()

        let resultA = await cache.get(key: "a")
        let resultB = await cache.get(key: "b")
        #expect(resultA == nil)
        #expect(resultB == nil)
    }

    @Test func cacheKeyNormalizesInputs() {
        let key1 = SerpApiCache.cacheKey(keyword: "  iOS Engineer  ", location: "San Francisco")
        let key2 = SerpApiCache.cacheKey(keyword: "ios engineer", location: "san francisco")
        #expect(key1 == key2)
    }
}

struct SerpApiServiceMockModeTests {

    @Test func mockModeReturnsSampleDataWithoutAPICall() async {
        let configuration = AppConfiguration(
            bundle: .main,
            environment: ["SERPAPI_KEY": "test-key-12345"]
        )
        let client = HTTPClient()
        let service = SerpApiService(
            client: client,
            configuration: configuration,
            mockMode: true
        )

        let request = JobSearchRequest()
        let result = await service.search(request: request)

        #expect(result.source == .serpapi)
        #expect(result.status.state == .sample)
        #expect(result.status.message?.contains("mock mode") == true)
        #expect(!result.listings.isEmpty)
    }

    @Test func missingCredentialsReturnsSampleData() async {
        // Configuration with no SERPAPI_KEY
        let configuration = AppConfiguration(bundle: .main, environment: [:])
        let client = HTTPClient()
        let service = SerpApiService(
            client: client,
            configuration: configuration,
            mockMode: false
        )

        let request = JobSearchRequest()
        let result = await service.search(request: request)

        #expect(result.source == .serpapi)
        #expect(result.status.state == .sample)
        #expect(result.status.message?.contains("SERPAPI_KEY") == true)
    }
}

struct SerpApiServiceIntegrationTests {

    /// Tests that the aggregation service correctly includes SerpApi as a provider
    /// by using stub providers — no real network calls.
    @Test func aggregationIncludesSerpApiProvider() async {
        struct StubSerpApiProvider: JobListingProvider {
            let source: JobSource = .serpapi
            func search(request: JobSearchRequest) async -> JobProviderResult {
                let listing = JobListing(
                    source: .serpapi,
                    title: "Google Jobs Result",
                    company: "Test Corp",
                    location: "Remote",
                    isRemote: true,
                    descriptionSnippet: "Found via SerpApi.",
                    rawSourceID: "serp-test-1"
                )
                return JobProviderResult(
                    source: .serpapi,
                    listings: [listing],
                    status: SourceFetchStatus(source: .serpapi, state: .live, resultCount: 1, message: nil),
                    hasMore: false
                )
            }
        }

        let service = AggregatedJobSearchService(providers: [StubSerpApiProvider()])
        var request = JobSearchRequest()
        request.sourceFilter = .serpapi

        let result = await service.search(request: request)

        #expect(result.listings.count == 1)
        #expect(result.listings.first?.source == .serpapi)
        #expect(result.listings.first?.title == "Google Jobs Result")
        #expect(result.statuses.first?.source == .serpapi)
        #expect(result.statuses.first?.state == .live)
    }
}
