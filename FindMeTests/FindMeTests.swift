//
//  FindMeTests.swift
//  FindMeTests
//
//  Created by Allen Russell on 3/17/26.
//

import Foundation
import Testing
@testable import FindMe

struct FindMeTests {

    @Test func adzunaDecodingParsesSalaryAndCompany() throws {
        let json = """
        {
          "results": [
            {
              "id": "123",
              "title": "iOS Engineer",
              "description": "<p>Build SwiftUI features.</p>",
              "company": { "display_name": "Northstar Labs" },
              "location": { "display_name": "Denver, CO" },
              "redirect_url": "https://example.com/jobs/123",
              "created": "2026-03-17T12:00:00Z",
              "salary_min": 120000,
              "salary_max": 150000,
              "contract_time": "full_time"
            }
          ]
        }
        """

        let response = try JSONDecoder().decode(AdzunaSearchResponse.self, from: Data(json.utf8))
        let result = try #require(response.results.first)

        #expect(result.company?.displayName == "Northstar Labs")
        #expect(result.salaryMin == 120000)
        #expect(result.salaryMax == 150000)
        #expect(result.contractTime == "full_time")
    }

    @Test func usaJobsDecodingParsesNestedDescriptor() throws {
        let json = """
        {
          "SearchResult": {
            "SearchResultItems": [
              {
                "MatchedObjectDescriptor": {
                  "PositionID": "federal-1",
                  "PositionTitle": "IT Specialist",
                  "OrganizationName": "General Services Administration",
                  "QualificationSummary": "Support secure systems.",
                  "PositionURI": "https://example.com/usajobs/federal-1",
                  "ApplyURI": ["https://example.com/apply/federal-1"],
                  "PublicationStartDate": "2026-03-15T00:00:00Z",
                  "PositionLocationDisplay": "Washington, DC",
                  "PositionLocation": [{ "LocationName": "Washington, DC" }],
                  "PositionRemuneration": [{ "MinimumRange": "90000", "MaximumRange": "120000" }],
                  "PositionSchedule": [{ "Name": "Full-Time" }],
                  "UserArea": {
                    "Details": {
                      "JobSummary": "Lead platform delivery.",
                      "RemoteIndicator": true
                    }
                  }
                }
              }
            ]
          }
        }
        """

        let response = try JSONDecoder().decode(USAJobsResponse.self, from: Data(json.utf8))
        let item = try #require(response.searchResult.items.first)
        let descriptor = item.matchedObjectDescriptor

        #expect(descriptor.positionTitle == "IT Specialist")
        #expect(descriptor.organizationName == "General Services Administration")
        #expect(descriptor.userArea?.details?.remoteIndicator == true)
        #expect(descriptor.positionRemuneration?.first?.maximumRange == "120000")
    }

    @Test func aggregationDeduplicatesAndAppliesRemoteFilter() async {
        struct StubProvider: JobListingProvider {
            let source: JobSource
            let jobs: [JobListing]

            func search(request: JobSearchRequest) async -> JobProviderResult {
                JobProviderResult(
                    source: source,
                    listings: jobs,
                    status: SourceFetchStatus(source: source, state: .live, resultCount: jobs.count, message: nil),
                    hasMore: false
                )
            }
        }

        let duplicateA = JobListing(
            source: .adzuna,
            title: "iOS Engineer",
            company: "Northstar Labs",
            location: "Denver, CO",
            isRemote: true,
            salaryMin: 140000,
            salaryMax: 160000,
            currency: "USD",
            employmentType: "Full-Time",
            descriptionSnippet: "Remote iOS role.",
            descriptionFull: nil,
            postedDate: .now,
            applyURL: nil,
            listingURL: nil,
            rawSourceID: "a"
        )

        let duplicateB = JobListing(
            source: .jsearch,
            title: "iOS Engineer",
            company: "Northstar Labs",
            location: "Denver, CO",
            isRemote: true,
            salaryMin: 145000,
            salaryMax: 165000,
            currency: "USD",
            employmentType: "Full-Time",
            descriptionSnippet: "Duplicate remote role.",
            descriptionFull: nil,
            postedDate: .now.addingTimeInterval(-3600),
            applyURL: nil,
            listingURL: nil,
            rawSourceID: "b"
        )

        let onSite = JobListing(
            source: .arbeitnow,
            title: "iOS Designer",
            company: "Atlas Works",
            location: "Austin, TX",
            isRemote: false,
            salaryMin: 80000,
            salaryMax: 95000,
            currency: "USD",
            employmentType: "Part-Time",
            descriptionSnippet: "On-site design role.",
            descriptionFull: nil,
            postedDate: .now,
            applyURL: nil,
            listingURL: nil,
            rawSourceID: "c"
        )

        let service = AggregatedJobSearchService(
            providers: [
                StubProvider(source: .adzuna, jobs: [duplicateA]),
                StubProvider(source: .jsearch, jobs: [duplicateB]),
                StubProvider(source: .arbeitnow, jobs: [onSite])
            ]
        )

        var request = JobSearchRequest()
        request.remoteOnly = true
        let result = await service.search(request: request)

        #expect(result.listings.count == 1)
        #expect(result.listings.first?.title == "iOS Engineer")
    }

    @Test func usaJobsDateParsingSupportsLiveFormatWithoutTimezone() {
        let parsed = DateParsers.parse("2026-03-05T13:10:10.5000")
        #expect(parsed != nil)
    }

}
