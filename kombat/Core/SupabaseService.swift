//
//  SupabaseService.swift
//  kombat
//

import Foundation
import Supabase

/// Single shared Supabase client. Handles session persistence and token
/// refresh automatically; auth state survives app restarts via the keychain.
enum SupabaseService {
    static let client = SupabaseClient(
        supabaseURL: SupabaseConfig.projectURL,
        supabaseKey: SupabaseConfig.publishableKey
    )
}
