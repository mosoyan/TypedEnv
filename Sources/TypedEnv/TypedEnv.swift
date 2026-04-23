// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

#if canImport(RoutingKit)
import RoutingKit
#endif

#if canImport(NIOCore)
import NIOCore
#endif

// MARK: - Errors

/// Errors that can occur during environment variable resolution.
public enum EnvironmentError: Error {
    /// Thrown when the requested environment variable key does not exist.
    case missingKey(String)
    /// Thrown when the environment variable exists, but cannot be converted to the requested type.
    case invalidValue(String, expected: Any.Type)
}

// MARK: - Protocols

/// A type that provides access to environment variables.
/// Conforming types map a String key to a String value.
public protocol EnvironmentProvider: Sendable {
    func get(_ key: String) -> String?
}

// MARK: - Namespace Builder

/// An intermediate object used to build environment variable keys via dot-syntax chaining.
///
/// Every time you append a property (e.g., `.api`), it returns a new namespace with that string appended.
/// When you assign the result to an explicit type (e.g., `let auth: String = ...`), Swift resolves
/// the final value using the typed subscripts.
@dynamicMemberLookup
public struct EnvironmentNamespace: Sendable {
    /// The accumulated environment key prefix (e.g., "API_AUTH").
    private let prefix: String
    /// The underlying provider used to fetch the actual value when the chain terminates.
    private let provider: any EnvironmentProvider

    init(prefix: String, provider: any EnvironmentProvider) {
        self.prefix = prefix
        self.provider = provider
    }

    // MARK: Chaining Subscript (The Builder)

    /// Overload A: Returns another namespace to continue chaining (e.g., `.api.auth...`)
    /// Swift uses this when the expected return type is unknown or explicitly `EnvironmentNamespace`.
    public subscript(dynamicMember member: String) -> EnvironmentNamespace {
        let component = Self.formatKey(member)
        return EnvironmentNamespace(prefix: "\(prefix)_\(component)", provider: provider)
    }

    // MARK: Terminal Subscripts (The Resolvers)

#if canImport(RoutingKit)
    /// Overload B: Automatically converts string paths to Vapor's `[PathComponent]`.
    /// Terminates the chain and fetches the value.
    public subscript(dynamicMember member: String) -> [PathComponent] {
        get throws {
            // Fetch the raw string using the existing LosslessStringConvertible subscript
            let stringValue: String = try self[dynamicMember: member]
            return stringValue.pathComponents
        }
    }
#endif

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

    /// Overload D: Base resolver for any type conforming to `LosslessStringConvertible` (String, Int, Bool, etc.).
    /// Terminates the chain and fetches the value.
    public subscript<T: LosslessStringConvertible>(dynamicMember member: String) -> T {
        get throws {
            let component = Self.formatKey(member)
            let environmentKey = "\(prefix)_\(component)"

            guard let stringValue = provider.get(environmentKey) else {
                throw EnvironmentError.missingKey(environmentKey)
            }

            guard let result = T(stringValue) else {
                throw EnvironmentError.invalidValue(environmentKey, expected: T.self)
            }
            return result
        }
    }

    // MARK: Explicit Type Casting

    /// Fetches the current accumulated namespace path as a specific `LosslessStringConvertible` type.
    public func `as`<T: LosslessStringConvertible>(_ type: T.Type) throws -> T {
        guard let stringValue = provider.get(prefix) else {
            throw EnvironmentError.missingKey(prefix)
        }

        guard let value = T(stringValue) else {
            throw EnvironmentError.invalidValue(prefix, expected: T.self)
        }
        return value
    }

    /// Fetches the current accumulated namespace path safely, returning `nil` if missing or malformed.
    public func optional<T: LosslessStringConvertible>(_ type: T.Type) -> T? {
        guard let stringValue = provider.get(prefix) else { return nil }
        return T(stringValue)
    }

#if canImport(RoutingKit)
    /// Explicitly fetches the current accumulated namespace path as `[PathComponent]`.
    public func asPathComponents() throws -> [PathComponent] {
        let string: String = try self.as(String.self)
        return string.pathComponents
    }
#endif

#if canImport(NIOCore)
    /// Explicitly fetches the current accumulated namespace path as `TimeAmount`.
    public func asTimeAmount() throws -> TimeAmount {
        let string: String = try self.as(String.self)
        return parseTimeAmount(from: string) ?? .zero
    }
#endif

    // MARK: Helpers

    /// Converts camelCase member names into uppercase SNAKE_CASE.
    /// Example: `authSocial` -> `AUTH_SOCIAL`
    fileprivate static func formatKey(_ member: String) -> String {
        let snakeCase = member.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1_$2",
            options: .regularExpression
        )
        return snakeCase.uppercased()
    }
}

// MARK: - Default Provider

/// A fallback provider that returns `nil` for all keys. Used before `Env.configure()` is called.
struct _DefaultEnvironmentProvider: EnvironmentProvider {
    func get(_ key: String) -> String? {
        nil
    }
}

// MARK: - Root Environment

/// The root entry point for dynamically looking up environment variables.
/// Example Usage: `let url: String = try Env.api.auth.social`
@dynamicMemberLookup
public struct Environment: Sendable {

    // Unsafe nonisolated is used here to allow global mutation of the provider on startup.
    // It is expected that `configure` is only called once during application boot.
    nonisolated(unsafe)
    private static var _provider: any EnvironmentProvider = _DefaultEnvironmentProvider()

    /// Configures the global environment provider. Call this once during app initialization.
    public static func configure(_ provider: any EnvironmentProvider) {
        _provider = provider
    }

    /// Accessor for the configured provider.
    static var provider: any EnvironmentProvider {
        _provider
    }

    // MARK: Root Subscripts

    /// Overload A: Starts the chain from the root (e.g., `Env.api...`)
    static subscript(dynamicMember member: String) -> EnvironmentNamespace {
        let component = EnvironmentNamespace.formatKey(member)
        return EnvironmentNamespace(prefix: component, provider: provider)
    }

    /// Overload B: Root-level fetch (e.g., `let port: Int = try Env.port`)
    static subscript<T: LosslessStringConvertible>(dynamicMember member: String) -> T {
        get throws {
            let environmentKey = EnvironmentNamespace.formatKey(member)

            guard let stringValue = provider.get(environmentKey) else {
                throw EnvironmentError.missingKey(environmentKey)
            }

            guard let result = T(stringValue) else {
                throw EnvironmentError.invalidValue(environmentKey, expected: T.self)
            }
            return result
        }
    }
}

/// A convenient, shorter alias for `Environment`.
/// Allows you to use `Env.api.auth` or `Environment.api.auth` interchangeably.
public typealias Env = Environment

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
