//
//  AuthSession.swift
//  kombat
//

import Foundation

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let userID: String
    let phone: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }

    enum UserKeys: String, CodingKey {
        case id
        case phone
    }

    init(accessToken: String, refreshToken: String, userID: String, phone: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userID = userID
        self.phone = phone
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try container.decode(String.self, forKey: .refreshToken)
        let userContainer = try container.nestedContainer(keyedBy: UserKeys.self, forKey: .user)
        userID = try userContainer.decode(String.self, forKey: .id)
        phone = try userContainer.decodeIfPresent(String.self, forKey: .phone) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(refreshToken, forKey: .refreshToken)
        var userContainer = container.nestedContainer(keyedBy: UserKeys.self, forKey: .user)
        try userContainer.encode(userID, forKey: .id)
        try userContainer.encode(phone, forKey: .phone)
    }
}
