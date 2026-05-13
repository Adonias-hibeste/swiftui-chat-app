import SwiftUI

struct ChatView: View {
    @State private var messageText = ""
    
    var body: some View {
        VStack {
            // Custom Navigation Bar
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .padding(10)
                        .background(Color.blue.opacity(0.05))
                        .clipShape(Circle())
                }
                
                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading) {
                        Text("Ava Johnson")
                            .font(.headline)
                        Text("Typing securely")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button(action: {}) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
            .padding()
            
            // Encryption Banner
            HStack {
                Image(systemName: "checkmark.shield.fill")
                Text("End-to-end encrypted")
                    .font(.caption)
                    .bold()
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            
            ScrollView {
                Text("Today 9:41 AM")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical)
                
                VStack(spacing: 16) {
                    BubbleView(text: "Morning — I reviewed the treatment notes. Do you want the simplified summary first or the full detail?", isFromUser: false)
                    
                    BubbleView(text: "Please send the short version first. I mostly want the key next steps.", isFromUser: true)
                    
                    VStack(alignment: .leading) {
                        BubbleView(text: "Short version: hydration, rest, and symptom monitoring for the next 24 hours. If your fever rises or breathing changes, escalate immediately.", isFromUser: false)
                        
                        // Suggestion Card
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Suggested follow-up")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.blue)
                            Text("Log temperature every 4 hours and keep fluid intake consistent.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.03))
                        .cornerRadius(12)
                        .padding(.leading, 40)
                    }
                    
                    BubbleView(text: "Got it. Can you also send the hydration target?", isFromUser: true)
                }
                .padding()
            }
            
            // Input Area
            VStack {
                HStack(spacing: 12) {
                    SuggestionChip(title: "Hydration")
                    SuggestionChip(title: "Medication")
                    SuggestionChip(title: "Red flags")
                    Spacer()
                }
                .padding(.horizontal)
                
                HStack {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .padding(10)
                            .background(Color.blue.opacity(0.05))
                            .clipShape(Circle())
                    }
                    
                    TextField("Type a secure message", text: $messageText)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    
                    Button(action: {}) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
            .background(Color.white)
        }
    }
}

struct BubbleView: View {
    let text: String
    let isFromUser: Bool
    
    var body: some View {
        HStack {
            if isFromUser { Spacer() }
            Text(text)
                .padding()
                .background(isFromUser ? Color.blue : Color.white)
                .foregroundColor(isFromUser ? .white : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.1), lineWidth: isFromUser ? 0 : 1)
                )
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            if !isFromUser { Spacer() }
        }
        .padding(.horizontal, isFromUser ? 0 : 8)
    }
}

struct SuggestionChip: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.caption)
            .bold()
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.05))
            .foregroundColor(.blue)
            .cornerRadius(12)
    }
}
