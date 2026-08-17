//
//  SupabaseDatabaseClient.swift
//  kombat
//

import Foundation
import Supabase

enum SupabaseDatabaseClient {
    private struct ProfileUpsert: Encodable {
        let id: String
        let email: String
        var isSubscribed: Bool?
        var subscriptionProductID: String?

        enum CodingKeys: String, CodingKey {
            case id
            case email
            case isSubscribed = "is_subscribed"
            case subscriptionProductID = "subscription_product_id"
        }
    }

    /// Upserts the signed-in user's row in the `profiles` table. Pass `isSubscribed`/`productID`
    /// only when you actually know the current value — omitting them leaves those columns
    /// untouched instead of overwriting them with a stale guess.
    static func upsertProfile(email: String, isSubscribed: Bool? = nil, productID: String? = nil) async throws {
        let userID = try await SupabaseService.client.auth.session.user.id
        let payload = ProfileUpsert(
            id: userID.uuidString,
            email: email,
            isSubscribed: isSubscribed,
            subscriptionProductID: productID
        )
        try await SupabaseService.client.from("profiles").upsert(payload).execute()
    }
}
