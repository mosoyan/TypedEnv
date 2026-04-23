//
//  TypedEnv.swift
//  TypedEnv
//
//  Created by Ovsep Keropian on 23.04.26.
//

import Foundation

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
