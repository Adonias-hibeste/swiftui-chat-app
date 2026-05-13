import SwiftUI

struct InboxView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                // Header with Action Buttons
                HStack {
                    VStack(alignment: .leading) {
                        Text("Messages")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Inbox")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "camera.fill")
                            .padding(10)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Button(action: {}) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.blue)
                    TextField("Search conversations", text: $searchText)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .padding(.horizontal)
                
                // Filters
                HStack(spacing: 12) {
                    FilterChip(title: "All", isSelected: true)
                    FilterChip(title: "Unread", isSelected: false)
                    FilterChip(title: "Pinned", isSelected: false)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Message List
                List {
                    ConversationRow(name: "Ava Johnson", message: "Can we lock in the final mo...", time: "9:41", count: 2)
                    ConversationRow(name: "Noah Lee", message: "The revised product rende...", time: "8:18", count: 1)
                    ConversationRow(name: "Sofia Martinez", message: "Landing in 20 minutes — I will se...", time: "Yesterday", count: 0)
                    ConversationRow(name: "Design Circle", message: "Mika: The new icon pass finally f...", time: "Yesterday", count: 0)
                    ConversationRow(name: "Oliver Grant", message: "Thanks again — I pushed the pa...", time: "Mon", count: 0)
                }
                .listStyle(.plain)
            }
            .navigationBarHidden(true)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .bold))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.white)
            .foregroundColor(isSelected ? .white : .blue)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
            )
    }
}

struct ConversationRow: View {
    let name: String
    let message: String
    let time: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(Text(name.prefix(1)))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.headline)
                    Spacer()
                    Text(time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .listRowSeparator(.hidden)
    }
}
