//
//  Country.swift
//  kombat
//

import Foundation

struct Country: Identifiable, Equatable {
    let name: String
    let isoCode: String
    let dialCode: String

    var id: String { isoCode }

    var flag: String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in isoCode.uppercased().unicodeScalars {
            if let flagScalar = Unicode.Scalar(base + scalar.value) {
                flag.unicodeScalars.append(flagScalar)
            }
        }
        return flag
    }

    static let `default` = all.first { $0.isoCode == "US" }!

    static let all: [Country] = [
        Country(name: "United States", isoCode: "US", dialCode: "+1"),
        Country(name: "Canada", isoCode: "CA", dialCode: "+1"),
        Country(name: "United Kingdom", isoCode: "GB", dialCode: "+44"),
        Country(name: "Australia", isoCode: "AU", dialCode: "+61"),
        Country(name: "Germany", isoCode: "DE", dialCode: "+49"),
        Country(name: "France", isoCode: "FR", dialCode: "+33"),
        Country(name: "Spain", isoCode: "ES", dialCode: "+34"),
        Country(name: "Italy", isoCode: "IT", dialCode: "+39"),
        Country(name: "Netherlands", isoCode: "NL", dialCode: "+31"),
        Country(name: "Portugal", isoCode: "PT", dialCode: "+351"),
        Country(name: "Ireland", isoCode: "IE", dialCode: "+353"),
        Country(name: "Switzerland", isoCode: "CH", dialCode: "+41"),
        Country(name: "Sweden", isoCode: "SE", dialCode: "+46"),
        Country(name: "Norway", isoCode: "NO", dialCode: "+47"),
        Country(name: "Denmark", isoCode: "DK", dialCode: "+45"),
        Country(name: "Poland", isoCode: "PL", dialCode: "+48"),
        Country(name: "Mexico", isoCode: "MX", dialCode: "+52"),
        Country(name: "Brazil", isoCode: "BR", dialCode: "+55"),
        Country(name: "Argentina", isoCode: "AR", dialCode: "+54"),
        Country(name: "Colombia", isoCode: "CO", dialCode: "+57"),
        Country(name: "Chile", isoCode: "CL", dialCode: "+56"),
        Country(name: "Japan", isoCode: "JP", dialCode: "+81"),
        Country(name: "South Korea", isoCode: "KR", dialCode: "+82"),
        Country(name: "China", isoCode: "CN", dialCode: "+86"),
        Country(name: "India", isoCode: "IN", dialCode: "+91"),
        Country(name: "Singapore", isoCode: "SG", dialCode: "+65"),
        Country(name: "Philippines", isoCode: "PH", dialCode: "+63"),
        Country(name: "Indonesia", isoCode: "ID", dialCode: "+62"),
        Country(name: "Thailand", isoCode: "TH", dialCode: "+66"),
        Country(name: "Vietnam", isoCode: "VN", dialCode: "+84"),
        Country(name: "New Zealand", isoCode: "NZ", dialCode: "+64"),
        Country(name: "South Africa", isoCode: "ZA", dialCode: "+27"),
        Country(name: "Nigeria", isoCode: "NG", dialCode: "+234"),
        Country(name: "Egypt", isoCode: "EG", dialCode: "+20"),
        Country(name: "United Arab Emirates", isoCode: "AE", dialCode: "+971"),
        Country(name: "Saudi Arabia", isoCode: "SA", dialCode: "+966"),
        Country(name: "Israel", isoCode: "IL", dialCode: "+972"),
        Country(name: "Turkey", isoCode: "TR", dialCode: "+90"),
        Country(name: "Russia", isoCode: "RU", dialCode: "+7"),
        Country(name: "Ukraine", isoCode: "UA", dialCode: "+380"),
        Country(name: "Greece", isoCode: "GR", dialCode: "+30"),
        Country(name: "Austria", isoCode: "AT", dialCode: "+43"),
        Country(name: "Belgium", isoCode: "BE", dialCode: "+32")
    ].sorted { $0.name < $1.name }
}
