import SwiftMapper
import Foundation

@Mappable(targets: [UserDomain.self, UserEntity.self])
struct UserDTO: Codable {
    var id: UUID
    var name: String
    var test: [TestDTO]?
    var arr: [String]? = nil
    @MapIgnore(for: [UserEntity.self]) var password: String? = nil
    
    init(id: UUID, name: String, test: [TestDTO]?, arr: [String]?, password: String?) {
        self.id = id
        self.name = name
        self.test = test
        self.arr = arr
        self.password = password
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name = "api_name"
    }
}

@Mappable(targets: [UserDomain.self, UserDTO.self])
class UserEntity {
    var id: UUID = UUID()
    var name: String = ""
    var test: [TestEntity] = []
    var arr: [String] = []
    
    init() {}
    
    init(id: UUID, name: String, test: [TestEntity]?, arr: [String]?) {
        self.id = id
        self.name = name
        self.test = test ?? []
        self.arr = arr ?? []
    }
}

@Mappable(targets: [UserDTO.self, UserEntity.self])
struct UserDomain {
    var id: UUID = UUID()
    var name: String = ""
    var test: [TestDomain]?
    var arr: [String] = []
    @MapIgnore(for: [UserEntity.self]) var password: String?
}

@Mappable(targets: [TestDomain.self, TestEntity.self])
struct TestDTO: Codable {
    var id: UUID
    var test: String
    
    init(id: UUID, test: String) {
        self.id = id
        self.test = test
    }
}

@Mappable(targets: [TestEntity.self, TestDTO.self])
struct TestDomain: Identifiable {
    var id: UUID
    var test: String
}

@Mappable(targets: [TestDomain.self, TestDTO.self])
class TestEntity {
    var id: UUID = UUID()
    var test: String = ""

    init() {}
    
    init(id: UUID, test: String) {
        self.id = id
        self.test = test
    }
    
}

let testDTO = TestDTO(id: UUID(), test: "test")
let dto = UserDTO(id: UUID(), name: "Developer", test: [testDTO], arr: ["Test", "test2", "test3"], password: "123")
let domain = UserDomain(from: dto)

let entity = UserEntity(from: dto)

print("Mapped name: \(domain.name)")
print("Mapped test: \(domain.test?.first?.test ?? "error")")
print("Mapped arr 0: \(domain.arr.first ?? "error")")
print("Mapped arr 1: \(domain.arr[1] ?? "error")")
print("Mapped entity: \(entity.name)")
