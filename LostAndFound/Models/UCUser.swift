import Foundation

struct UCUser: Identifiable, Codable, Equatable {


    let id: String
    let name: String
    let email: String
    let role: UserRole
    let studentId: String
    let profileImageUrl: String?
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        email: String,
        role: UserRole = .student,
        studentId: String = "",
        profileImageUrl: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.studentId = studentId
        self.profileImageUrl = profileImageUrl
        self.createdAt = createdAt
    }
}
