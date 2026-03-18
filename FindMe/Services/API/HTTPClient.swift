import Foundation

actor HTTPClient {
    enum HTTPError: LocalizedError {
        case invalidResponse
        case badStatusCode(Int)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                "The server response was invalid."
            case let .badStatusCode(code):
                "The server returned status code \(code)."
            }
        }
    }

    func get<T: Decodable>(
        _ type: T.Type,
        url: URL,
        headers: [String: String] = [:],
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response)
        return try decoder.decode(T.self, from: data)
    }

    func post<T: Decodable, Body: Encodable>(
        _ type: T.Type,
        url: URL,
        body: Body,
        headers: [String: String] = [:],
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response)
        return try decoder.decode(T.self, from: data)
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw HTTPError.badStatusCode(httpResponse.statusCode)
        }
    }
}
