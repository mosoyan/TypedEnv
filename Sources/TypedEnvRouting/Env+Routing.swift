//
//  Env+Routing.swift
//  TypedEnv
//
//  Created by Ovsep Keropian on 23.04.26.
//

#if canImport(RoutingKit)
import RoutingKit
import TypedEnv
#endif

extension EnvironmentNamespace {
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

#if canImport(RoutingKit)
    /// Explicitly fetches the current accumulated namespace path as `[PathComponent]`.
    public func asPathComponents() throws -> [PathComponent] {
        let string: String = try self.as(String.self)
        return string.pathComponents
    }
#endif
}
