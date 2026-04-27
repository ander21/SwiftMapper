SwiftMapper 🚀
SwiftMapper is a lightweight, compile-time mapping library powered by Swift Macros. It eliminates the boilerplate of writing manual initializers for DTOs, Domain Models, and Database Entities.

Unlike traditional mappers, SwiftMapper analyzes your code at compile-time, providing zero runtime overhead and immediate feedback on type mismatches.

📦 Installation
Add SwiftMapper to your project using Swift Package Manager:

In Xcode, go to File > Add Package Dependencies...

Paste the repository URL: https://github.com/YOUR_USERNAME/SwiftMapper.git

Select Dependency Rule: Up to Next Major Version.

Alternatively, add it to your Package.swift:

Swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/SwiftMapper.git", from: "1.0.0")
]
🚀 Usage
Basic Mapping
Annotate your models with @Mappable and specify the source types.

Swift
import SwiftMapper

struct UserDTO: Codable {
    var id: UUID
    var api_name: String
}

@Mappable(targets: [UserDTO.self])
struct User {
    var id: UUID
    @MapKey("api_name") var name: String
}

// SwiftMapper automatically generates:
// let user = User(from: dto)
Nested & Optional Mapping
SwiftMapper recursively maps nested objects and arrays. It also handles optional mismatches by providing smart defaults for primitives.

Swift
@Mappable(targets: [TaskDTO.self])
struct Task {
    var title: String
}

@Mappable(targets: [UserDTO.self])
struct UserDomain {
    var name: String      // Target non-optional, source optional? Generates: ?? ""
    var tasks: [Task]?    // Maps array: source.tasks?.map { Task(from: $0) }
}
🛠 Attributes
@Mappable(targets: [...]): Generates init(from:) for each target.

@MapKey("source_field"): Maps a property to a differently named field in the source.

@MapIgnore: Excludes a property from being mapped.

⚠️ Requirements
Swift 5.9+ (Xcode 15+)

iOS 13+ / macOS 10.15+
