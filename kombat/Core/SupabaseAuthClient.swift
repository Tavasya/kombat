//
//  SupabaseAuthClient.swift
//  kombat
//

import Foundation

enum SupabaseAuthError: LocalizedError {
    case server(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .server(let message): return message
        case .invalidResponse: return "Something went wrong. Please try again."
        }
    }
}

enum SignUpOutcome {
    case session(AuthSession)
    /// Supabase's "Confirm email" setting is on, so no session is issued until the user
    /// clicks the confirmation link Supabase emails them.
    case confirmationRequired
}

enum SupabaseAuthClient {
    private static var session: URLSession { .shared }

    private static func makeRequest(path: String, body: [String: Any]) throws -> URLRequest {
        let url = SupabaseConfig.projectURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    /// Creates a new account. Returns `.confirmationRequired` if the project has email
    /// confirmation enabled (the default), since Supabase won't issue a session until then.
    static func signUp(email: String, password: String) async throws -> SignUpOutcome {
        let request = try makeRequest(path: "/auth/v1/signup", body: ["email": email, "password": password])
        let (data, response) = try await session.data(for: request)
        try validate(data: data, response: response)
        if let session = try? JSONDecoder().decode(AuthSession.self, from: data) {
            return .session(session)
        }
        return .confirmationRequired
    }

    /// Logs in an existing, confirmed account.
    static func signIn(email: String, password: String) async throws -> AuthSession {
        let request = try makeRequest(path: "/auth/v1/token?grant_type=password", body: ["email": email, "password": password])
        let (data, response) = try await session.data(for: request)
        try validate(data: data, response: response)
        do {
            return try JSONDecoder().decode(AuthSession.self, from: data)
        } catch {
            throw SupabaseAuthError.invalidResponse
        }
    }

    private static func validate(data: Data, response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseAuthError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let message = (json["error_description"] as? String)
                    ?? (json["msg"] as? String)
                    ?? (json["message"] as? String)
                    ?? "Request failed (\(httpResponse.statusCode))."
                throw SupabaseAuthError.server(message)
            }
            throw SupabaseAuthError.server("Request failed (\(httpResponse.statusCode)).")
        }
    }
}
