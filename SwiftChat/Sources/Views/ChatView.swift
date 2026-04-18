import SwiftUI

/// Chat View — displays messages in a conversation with real-time updates,
/// typing indicators, and rich message input.
struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    @State private var showMediaPicker = false
    @State private var showCamera = false
    @State private var messageText = ""
    @Namespace private var scrollSpace
    
    let conversation: Conversation
    
    init(conversation: Conversation) {
        self.conversation = conversation
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversationId: conversation.id))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.groupedMessages, id: \.date) { group in
                            // Date Header
                            Text(group.date)
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                            
                            ForEach(group.messages) { message in
                                MessageBubbleView(
                                    message: message,
                                    showAvatar: conversation.isGroup && !message.isFromCurrentUser
                                )
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .opacity
                                ))
                            }
                        }
                        
                        // Typing Indicator
                        if viewModel.isOtherUserTyping {
                            TypingIndicatorView()
                                .padding(.leading, 16)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        
                        // Scroll anchor
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    withAnimation(.spring(response: 0.3)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onAppear {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            
            Divider()
            
            // Message Input Bar
            messageInputBar
        }
        .navigationTitle(conversation.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { /* Voice call */ }) {
                        Image(systemName: "phone.fill")
                    }
                    Button(action: { /* Video call */ }) {
                        Image(systemName: "video.fill")
                    }
                }
            }
        }
        .task {
            await viewModel.loadMessages()
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
    
    // MARK: - Message Input Bar
    private var messageInputBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Attachment Button
            Button {
                showMediaPicker = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.accent)
            }
            
            // Text Input
            HStack(alignment: .bottom) {
                TextField("Message...", text: $messageText, axis: .vertical)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .onChange(of: messageText) { _, newValue in
                        Task {
                            await WebSocketService.shared.sendTypingIndicator(
                                conversationId: conversation.id,
                                isTyping: !newValue.isEmpty
                            )
                        }
                    }
                
                // Emoji Button
                Button(action: { /* Emoji picker */ }) {
                    Image(systemName: "face.smiling")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            
            // Send / Voice Button
            Button {
                if messageText.isEmpty {
                    // Record voice message
                } else {
                    sendMessage()
                }
            } label: {
                Image(systemName: messageText.isEmpty ? "mic.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.accent)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showMediaPicker) {
            MediaPickerView { attachments in
                Task {
                    await viewModel.sendMediaMessage(attachments: attachments)
                }
            }
        }
    }
    
    // MARK: - Send Message
    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        messageText = ""
        
        Task {
            await viewModel.sendTextMessage(text)
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: Message
    let showAvatar: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromCurrentUser { Spacer(minLength: 60) }
            
            if showAvatar && !message.isFromCurrentUser {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Text("A")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
            }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                // Message Content
                switch message.type {
                case .text:
                    textBubble
                case .image:
                    imageBubble
                case .voice:
                    voiceBubble
                default:
                    textBubble
                }
                
                // Status + Time
                HStack(spacing: 4) {
                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if message.isFromCurrentUser {
                        Image(systemName: message.status.icon)
                            .font(.caption2)
                            .foregroundStyle(message.status == .read ? .accent : .secondary)
                    }
                }
            }
            
            if !message.isFromCurrentUser { Spacer(minLength: 60) }
        }
    }
    
    private var textBubble: some View {
        Text(message.content)
            .font(.body)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                message.isFromCurrentUser
                    ? AnyShapeStyle(.accent)
                    : AnyShapeStyle(.ultraThinMaterial)
            )
            .foregroundStyle(message.isFromCurrentUser ? .white : .primary)
            .clipShape(BubbleShape(isFromCurrentUser: message.isFromCurrentUser))
    }
    
    private var imageBubble: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .frame(width: 220, height: 180)
            .overlay {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
    }
    
    private var voiceBubble: some View {
        HStack(spacing: 12) {
            Button(action: { /* Play voice */ }) {
                Image(systemName: "play.fill")
                    .foregroundStyle(message.isFromCurrentUser ? .white : .accent)
            }
            
            // Waveform placeholder
            HStack(spacing: 2) {
                ForEach(0..<20, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(message.isFromCurrentUser ? Color.white.opacity(0.7) : Color.accent.opacity(0.5))
                        .frame(width: 2, height: CGFloat.random(in: 4...20))
                }
            }
            
            Text("0:15")
                .font(.caption2)
                .foregroundStyle(message.isFromCurrentUser ? .white.opacity(0.8) : .secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            message.isFromCurrentUser
                ? AnyShapeStyle(.accent)
                : AnyShapeStyle(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Bubble Shape
struct BubbleShape: Shape {
    let isFromCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 6
        
        var path = Path()
        
        if isFromCurrentUser {
            path.addRoundedRect(
                in: CGRect(x: 0, y: 0, width: rect.width - tailSize, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
        } else {
            path.addRoundedRect(
                in: CGRect(x: tailSize, y: 0, width: rect.width - tailSize, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
        }
        
        return path
    }
}

// MARK: - Typing Indicator
struct TypingIndicatorView: View {
    @State private var animatingDot = 0
    
    var body: some View {
        HStack(alignment: .bottom) {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(.secondary)
                        .frame(width: 6, height: 6)
                        .offset(y: animatingDot == index ? -4 : 0)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4).repeatForever()) {
                    animatingDot = (animatingDot + 1) % 3
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Chat ViewModel (stub)
@MainActor
final class ChatViewModel: ObservableObject {
    let conversationId: String
    @Published var messages: [Message] = []
    @Published var isOtherUserTyping = false
    
    struct MessageGroup: Identifiable {
        let id = UUID()
        let date: String
        let messages: [Message]
    }
    
    var groupedMessages: [MessageGroup] {
        let grouped = Dictionary(grouping: messages) { $0.formattedDate }
        return grouped.map { MessageGroup(date: $0.key, messages: $0.value) }
            .sorted { $0.messages.first?.createdAt ?? Date() < $1.messages.first?.createdAt ?? Date() }
    }
    
    init(conversationId: String) {
        self.conversationId = conversationId
    }
    
    func loadMessages() async {
        // Load from Core Data cache, then fetch from API
    }
    
    func sendTextMessage(_ text: String) async {
        let message = Message(
            id: UUID().uuidString,
            conversationId: conversationId,
            senderId: AuthService.shared.currentUserId,
            content: text,
            type: .text,
            status: .sending,
            replyTo: nil,
            attachments: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        messages.append(message)
        
        do {
            try await WebSocketService.shared.sendMessage(message)
        } catch {
            print("❌ Failed to send: \(error)")
        }
    }
    
    func sendMediaMessage(attachments: [MediaAttachment]) async {
        // Upload media then send message
    }
    
    func startListening() {
        WebSocketService.shared.onMessageReceived = { [weak self] message in
            Task { @MainActor in
                self?.messages.append(message)
            }
        }
    }
    
    func stopListening() {
        WebSocketService.shared.onMessageReceived = nil
    }
}

// MARK: - Media Picker (stub)
struct MediaPickerView: View {
    let onSelect: ([MediaAttachment]) -> Void
    
    var body: some View {
        Text("Media Picker")
    }
}

#Preview {
    NavigationStack {
        ChatView(conversation: Conversation(
            id: "1",
            type: .direct,
            name: "John Doe",
            avatarUrl: nil,
            participants: [],
            lastMessage: nil,
            unreadCount: 0,
            isPinned: false,
            isMuted: false,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
