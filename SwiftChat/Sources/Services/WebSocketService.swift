import Foundation

/// WebSocket Service — manages real-time connection for instant messaging.
/// Uses URLSessionWebSocketTask with automatic reconnection and heartbeat.
@MainActor
final class WebSocketService: ObservableObject {
    static let shared = WebSocketService()
    
    @Published var connectionState: ConnectionState = .disconnected
    @Published var isTyping: [String: Bool] = [:]
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession
    private var pingTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let baseReconnectDelay: TimeInterval = 1.0
    
    // Event handlers
    var onMessageReceived: ((Message) -> Void)?
    var onTypingIndicator: ((String, Bool) -> Void)?
    var onUserStatusChanged: ((String, Bool) -> Void)?
    var onMessageStatusUpdate: ((String, MessageStatus) -> Void)?
    
    private init() {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Connection Management
    func connect(token: String) {
        guard connectionState != .connected else { return }
        connectionState = .connecting
        
        guard let url = URL(string: "\(AppConfig.wsBaseURL)/ws?token=\(token)") else {
            connectionState = .disconnected
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        connectionState = .connected
        reconnectAttempts = 0
        
        startListening()
        startPing()
        
        print("✅ WebSocket connected")
    }
    
    func disconnect() {
        connectionState = .disconnected
        pingTimer?.invalidate()
        pingTimer = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    // MARK: - Send Messages
    func sendMessage(_ message: Message) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let payload = WebSocketPayload(
            type: .message,
            data: try encoder.encode(message)
        )
        
        let jsonData = try encoder.encode(payload)
        let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        
        try await webSocketTask?.send(.string(jsonString))
    }
    
    func sendTypingIndicator(conversationId: String, isTyping: Bool) async {
        let payload: [String: Any] = [
            "type": "typing",
            "conversationId": conversationId,
            "isTyping": isTyping
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let string = String(data: data, encoding: .utf8) else { return }
        
        try? await webSocketTask?.send(.string(string))
    }
    
    func sendReadReceipt(messageId: String) async {
        let payload: [String: Any] = [
            "type": "read_receipt",
            "messageId": messageId
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let string = String(data: data, encoding: .utf8) else { return }
        
        try? await webSocketTask?.send(.string(string))
    }
    
    // MARK: - Listen for Messages
    private func startListening() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let message):
                    self?.handleWebSocketMessage(message)
                    self?.startListening() // Continue listening
                    
                case .failure(let error):
                    print("❌ WebSocket receive error: \(error)")
                    self?.handleDisconnect()
                }
            }
        }
    }
    
    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8) else { return }
            parsePayload(data)
            
        case .data(let data):
            parsePayload(data)
            
        @unknown default:
            break
        }
    }
    
    private func parsePayload(_ data: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let payload = try? decoder.decode(WebSocketPayload.self, from: data) else { return }
        
        switch payload.type {
        case .message:
            if let message = try? decoder.decode(Message.self, from: payload.data) {
                onMessageReceived?(message)
            }
            
        case .typing:
            if let info = try? JSONSerialization.jsonObject(with: payload.data) as? [String: Any],
               let userId = info["userId"] as? String,
               let isTyping = info["isTyping"] as? Bool {
                self.isTyping[userId] = isTyping
                onTypingIndicator?(userId, isTyping)
            }
            
        case .statusUpdate:
            if let info = try? JSONSerialization.jsonObject(with: payload.data) as? [String: Any],
               let messageId = info["messageId"] as? String,
               let statusRaw = info["status"] as? String,
               let status = MessageStatus(rawValue: statusRaw) {
                onMessageStatusUpdate?(messageId, status)
            }
            
        case .userStatus:
            if let info = try? JSONSerialization.jsonObject(with: payload.data) as? [String: Any],
               let userId = info["userId"] as? String,
               let isOnline = info["isOnline"] as? Bool {
                onUserStatusChanged?(userId, isOnline)
            }
            
        case .ping, .pong:
            break
        }
    }
    
    // MARK: - Heartbeat
    private func startPing() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { error in
                if let error = error {
                    print("❌ Ping failed: \(error)")
                    Task { @MainActor in
                        self?.handleDisconnect()
                    }
                }
            }
        }
    }
    
    // MARK: - Reconnection
    private func handleDisconnect() {
        connectionState = .disconnected
        pingTimer?.invalidate()
        
        guard reconnectAttempts < maxReconnectAttempts else {
            connectionState = .failed
            print("❌ Max reconnection attempts reached")
            return
        }
        
        connectionState = .reconnecting
        reconnectAttempts += 1
        
        // Exponential backoff
        let delay = baseReconnectDelay * pow(2.0, Double(reconnectAttempts - 1))
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if let token = AuthService.shared.accessToken {
                connect(token: token)
            }
        }
    }
}

// MARK: - Supporting Types
enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case failed
    
    var description: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .reconnecting: return "Reconnecting..."
        case .failed: return "Connection Failed"
        }
    }
}

struct WebSocketPayload: Codable {
    let type: PayloadType
    let data: Data
}

enum PayloadType: String, Codable {
    case message
    case typing
    case statusUpdate = "status_update"
    case userStatus = "user_status"
    case ping
    case pong
}

// MARK: - Auth Service (stub)
final class AuthService {
    static let shared = AuthService()
    var currentUserId: String = ""
    var accessToken: String?
}

// MARK: - App Config
enum AppConfig {
    static let wsBaseURL = "wss://api.swiftchat.app"
    static let apiBaseURL = "https://api.swiftchat.app/v1"
}
