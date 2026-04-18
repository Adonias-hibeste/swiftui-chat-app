import Foundation

// MARK: - Message Model
struct Message: Identifiable, Codable, Hashable {
    let id: String
    let conversationId: String
    let senderId: String
    let content: String
    let type: MessageType
    let status: MessageStatus
    let replyTo: String?
    let attachments: [MediaAttachment]
    let createdAt: Date
    let updatedAt: Date
    
    var isFromCurrentUser: Bool {
        senderId == AuthService.shared.currentUserId
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: createdAt)
    }
    
    var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(createdAt) {
            return "Today"
        } else if calendar.isDateInYesterday(createdAt) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: createdAt)
        }
    }
}

enum MessageType: String, Codable {
    case text
    case image
    case video
    case voice
    case file
    case location
    case system
}

enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
    
    var icon: String {
        switch self {
        case .sending: return "clock"
        case .sent: return "checkmark"
        case .delivered: return "checkmark.circle"
        case .read: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Media Attachment
struct MediaAttachment: Identifiable, Codable, Hashable {
    let id: String
    let type: AttachmentType
    let url: String
    let thumbnailUrl: String?
    let fileName: String?
    let fileSize: Int64?
    let duration: Double? // For voice/video
    let width: Int?
    let height: Int?
    
    var formattedFileSize: String {
        guard let size = fileSize else { return "" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

enum AttachmentType: String, Codable {
    case image
    case video
    case audio
    case document
}

// MARK: - Conversation Model
struct Conversation: Identifiable, Codable {
    let id: String
    let type: ConversationType
    let name: String?
    let avatarUrl: String?
    let participants: [User]
    let lastMessage: Message?
    let unreadCount: Int
    let isPinned: Bool
    let isMuted: Bool
    let createdAt: Date
    let updatedAt: Date
    
    var displayName: String {
        if let name = name { return name }
        let otherParticipants = participants.filter { !$0.isCurrentUser }
        return otherParticipants.map { $0.displayName }.joined(separator: ", ")
    }
    
    var isGroup: Bool { type == .group }
    
    var lastMessagePreview: String {
        guard let msg = lastMessage else { return "No messages yet" }
        switch msg.type {
        case .text: return msg.content
        case .image: return "📷 Photo"
        case .video: return "🎥 Video"
        case .voice: return "🎤 Voice Message"
        case .file: return "📎 File"
        case .location: return "📍 Location"
        case .system: return msg.content
        }
    }
}

enum ConversationType: String, Codable {
    case direct
    case group
}

// MARK: - User Model
struct User: Identifiable, Codable, Hashable {
    let id: String
    let username: String
    let displayName: String
    let avatarUrl: String?
    let bio: String?
    let isOnline: Bool
    let lastSeen: Date?
    
    var isCurrentUser: Bool {
        id == AuthService.shared.currentUserId
    }
    
    var lastSeenText: String {
        guard !isOnline else { return "Online" }
        guard let lastSeen = lastSeen else { return "Offline" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Last seen \(formatter.localizedString(for: lastSeen, relativeTo: Date()))"
    }
    
    var initials: String {
        let components = displayName.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
}
