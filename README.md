# TypedEnv

**TypedEnv:** A type-safe environment variable parser for Swift. Access .env SNAKE_CASE variables using your preferred style: nested dots (Env.snake.case) or camelCase (Env.snakeCase). Features automatic type casting for Swift types, Vapor PathComponents, and NIOCore TimeAmounts via elegant @dynamicMemberLookup.

It eliminates fragile string-based access and replaces it with a readable, composable, and testable approach.

---

## ✨ Features

- 🔗 **Fluent API**
  ```swift
  try Env.api.auth.token.as(String.self)
  ```

- 🧩 **Automatic key building**
  ```swift
  Env.api.auth.token  ->  API_AUTH_TOKEN
  ```

- 🔒 **Type-safe access**
  ```swift
  let timeout = try Env.api.timeout.as(Int.self)
  let enabled = try Env.feature.flag.as(Bool.self)
  ```

- ⚙️ **Dependency Injection**
  ```swift
  Env.configure(MyProvider())
  ```

- 🚫 **No crashes**
  Uses `throws` instead of `fatalError`

- 🧪 **Testable**
  Easily mock environment values

- 🔌 **Extensible**
  Supports custom types like `TimeAmount` and `PathComponent`

---

## 🚀 Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
.package(url: "https://github.com/yourusername/TypedEnv.git", from: "1.0.0")
```

---

## 🧠 Usage

### 1. Configure provider

```swift
struct ProcessInfoProvider: EnvironmentProvider {
    func get(_ key: String) -> String? {
        ProcessInfo.processInfo.environment[key]
    }
}

Env.configure(ProcessInfoProvider())
```

---

### 2. Access values

```swift
let token = try Env.api.auth.token.as(String.self)
let timeout = try Env.api.timeout.as(Int.self)
```

---

### 3. Root-level access

```swift
let port: Int = try Env.port
```

---

### 4. Optional values

```swift
let token = Env.api.auth.token.optional(String.self)
```

---

## 🔌 Supported Types

### Built-in (`LosslessStringConvertible`)

- `String`
- `Int`
- `Double`
- `Bool`

---

### RoutingKit (optional)

If `RoutingKit` is available:

```swift
let route = try Env.api.route.asPathComponents()
```

---

### NIOCore (optional)

If `NIOCore` is available:

```swift
let timeout = try Env.api.timeout.asTimeAmount()
```

Supported formats:
- `"1h"` → 1 hour
- `"30m"` → 30 minutes
- `"45s"` → 45 seconds

---

## 🧱 How it works

TypedEnv transforms chained properties into environment keys:

```swift
Env.api.auth.token
```

⬇️ becomes:

```
API_AUTH_TOKEN
```

Then:
1. Fetches value from `EnvironmentProvider`
2. Converts it to the requested type

---

## 🧩 Custom Provider

```swift
struct MyProvider: EnvironmentProvider {
    func get(_ key: String) -> String? {
        // Custom logic (dotenv, remote config, etc.)
    }
}
```

---

## ⚠️ Important

You must call:

```swift
Env.configure(...)
```

before accessing values, otherwise all lookups will fail.

---

## 📌 Why TypedEnv?

- Avoid stringly-typed bugs  
- Improve readability  
- Centralize configuration access  
- Make environment usage testable  

---

## 📄 License

Apache License 2.0
