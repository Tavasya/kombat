//
//  SupabaseConfig.swift
//  kombat
//

import Foundation

enum SupabaseConfig {
    static let projectURL = URL(string: "https://nspswimmgzlsyqtmniqm.supabase.co")!

    /// Safe to ship in client code — this is the publishable (anon) key, not the secret key.
    static let publishableKey = "sb_publishable_NeEotl6mc7NpNN71fTAg0g_rJroT1-4"
}
