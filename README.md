# SwiftMapper 🚀

**SwiftMapper** is a lightweight, compile-time mapping library powered by **Swift Macros**. It eliminates the boilerplate of writing manual initializers for **DTOs**, **Domain Models**, and **Database Entities**.

Unlike traditional mappers, SwiftMapper analyzes your code at compile-time, providing **zero runtime overhead** and **immediate feedback** on type mismatches.

## 📦 Installation

Add SwiftMapper to your project using **Swift Package Manager**:

1. In Xcode, go to **File > Add Package Dependencies...**
2. Paste the repository URL: `https://github.com/ander21/SwiftMapper.git`
3. Select **Dependency Rule**: `Up to Next Major Version`.

Alternatively, add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "[https://github.com/ander21/SwiftMapper.git](https://github.com/ander21/SwiftMapper.git)", from: "1.0.0")
]
```

## 🚀 Usage

Basic Mapping Annotate your models with @Mappable and specify the source types.

```swift
import SwiftMapper

struct UserDTO: Codable {
    var id: UUID
    var name: String
}

@Mappable(targets: [UserDTO.self])
struct User {
    var id: UUID
    var name: String
}

// SwiftMapper automatically generates:
// let user = User(from: dto)
```
With classes:
```swift
import SwiftMapper

@Mappable(targets: [UserEntity.self])
struct UserDTO: Codable {
    var id: UUID
    var name: String
    //@MapIgnore - ignores property, @MapIgnore(for: [UserEntity.self]) - ignores property for target class/structure
    @MapIgnore var password: String
}

@Mappable(targets: [UserDTO.self])
class UserEntity {
    var id: UUID = UUID()
    var name: String = ""

    // Required for classes (Macros adds convenience init(from: .Type) {
    //    self.init()
    // })
    init() {}
}
```
