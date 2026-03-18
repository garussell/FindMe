import Foundation

struct AggregatedJobSearchService: Sendable {
    let providers: [any JobListingProvider]

    func search(request: JobSearchRequest) async -> AggregatedJobSearchResult {
        let activeSources = Set(request.sourceFilter.includedSources)
        let activeProviders = providers.filter { activeSources.contains($0.source) }

        let results = await withTaskGroup(of: JobProviderResult.self) { group in
            for provider in activeProviders {
                group.addTask {
                    await provider.search(request: request)
                }
            }

            var collected: [JobProviderResult] = []
            for await result in group {
                collected.append(result)
            }
            return collected.sorted { $0.source.displayName < $1.source.displayName }
        }

        let merged = results
            .flatMap(\.listings)
            .filter { listing in
                guard !request.remoteOnly || listing.isRemote else { return false }

                if let minimum = request.salaryMinimum {
                    let advertisedSalary = listing.salaryMax ?? listing.salaryMin
                    guard let advertisedSalary, Int(advertisedSalary) >= minimum else { return false }
                }

                switch request.employmentType {
                case .any:
                    return true
                case .fullTime:
                    return listing.employmentType?.localizedCaseInsensitiveContains("full") ?? false
                case .partTime:
                    return listing.employmentType?.localizedCaseInsensitiveContains("part") ?? false
                }
            }
            .deduplicatedAndSorted()

        return AggregatedJobSearchResult(
            listings: merged,
            statuses: results.map(\.status),
            canLoadMore: results.contains(where: \.hasMore)
        )
    }
}
