//
//  TypedEnvNIO.swift
//  TypedEnv
//
//  Created by Ovsep Keropian on 23.04.26.
//

import Foundation
#if canImport(NIOCore)
import NIOCore
import TypedEnv
#endif

extension EnvironmentNamespace {

#if canImport(NIOCore)
    /// Overload C: Automatically converts string values (e.g., "1h", "30m") to `TimeAmount`.
    /// Terminates the chain and fetches the value.
    public subscript(dynamicMember member: String) -> TimeAmount {
        get throws {
            let stringValue: String = try self[dynamicMember: member]
            return parseTimeAmount(from: stringValue) ?? .zero
        }
    }
#endif

#if canImport(NIOCore)
    /// Explicitly fetches the current accumulated namespace path as `TimeAmount`.
    public func asTimeAmount() throws -> TimeAmount {
        let string: String = try self.as(String.self)
        return parseTimeAmount(from: string) ?? .zero
    }
#endif
}

// MARK: - Time Parser Helper

/// Parses a string representation of time into a `TimeAmount`.
/// Supports hours ("h"), minutes ("m"), and seconds ("s").
/// Example: "2h" -> 7200 seconds, "30m" -> 1800 seconds.
#if canImport(NIOCore)
private func parseTimeAmount(from env: String?) -> TimeAmount? {
    guard let env = env?.lowercased(), !env.isEmpty else { return nil }

    let unitMultipliers: [String: Int64] = [
        "h": 60 * 60,
        "m": 60,
        "s": 1
    ]

    // Regex matches a series of digits followed by exactly one of: h, m, or s.
    let pattern = #"^(\d+)([hms])$"#
    let regex = try? NSRegularExpression(pattern: pattern, options: [])

    if let match = regex?.firstMatch(in: env, range: NSRange(env.startIndex..., in: env)),
       let numberRange = Range(match.range(at: 1), in: env),
       let unitRange = Range(match.range(at: 2), in: env) {

        let number = Int64(env[numberRange]) ?? 0
        let unit = String(env[unitRange])

        if let multiplier = unitMultipliers[unit] {
            return .seconds(number * multiplier)
        }
    }
    return nil
}
#endif

