//
//  SupabaseDatabaseClient.swift
//  kombat
//

import Foundation

enum SupabaseDatabaseClient {
    /// Upserts the signed-in user's row in the `profiles` table. Pass `isSubscribed`/`productID`
    /// only when you actually know the current value — omitting them leaves those columns
    /// untouched instead of overwriting them with a stale guess.
    static func upsertProfile(
        accessToken: String,
        userID: String,
        email: String,
        isSubscribed: Bool? = nil,
        productID: String? = nil
    ) async throws {
        let url = SupabaseConfig.projectURL.appendingPathComponent("/rest/v1/profiles")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")

        var body: [String: Any] = [
            "id": userID,
            "email": email,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        if let isSubscribed {
            body["is_subscribed"] = isSubscribed
        }
        if let productID {
            body["subscription_product_id"] = productID
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
            throw SupabaseAuthError.server(message ?? "Couldn't sync profile to the database.")
        }
    }
}
