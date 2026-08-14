import Foundation
import SwiftUI

struct DinoChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = DinoChatViewModel()

    private let suggestions = [
        "How do I start a savings jar?",
        "What is a good allowance plan?",
        "What does interest mean?"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(model.messages) { message in
                                DinoMessageBubble(message: message)
                                    .id(message.id)
                            }

                            if model.isSending {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Dino is thinking…")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .id("typing")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: model.messages.count) { _ in
                        if let lastMessage = model.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: model.isSending) { sending in
                        if sending {
                            withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    if model.messages.count == 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Button(suggestion) {
                                        model.send(suggestion)
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(model.isSending)
                                }
                            }
                        }
                    }

                    Text("Family note: do not share names, addresses, passwords, card numbers, or school details.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .bottom, spacing: 10) {
                        TextField("Ask about saving, spending, or allowance", text: $model.draft, axis: .vertical)
                            .lineLimit(1...4)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.send)
                            .onSubmit { model.sendDraft() }

                        Button {
                            model.sendDraft()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 34))
                        }
                        .disabled(!model.canSend)
                        .accessibilityLabel("Send message")
                    }
                }
                .padding()
                .background(.regularMaterial)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Ask Dino Munch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("New") { model.startNewChat() }
                }
            }
            .alert("Dino could not answer", isPresented: $model.isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(model.errorMessage)
            }
        }
    }
}

private struct DinoMessageBubble: View {
    let message: DinoChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromDino {
                Text("🦕")
                    .font(.title2)
                    .accessibilityHidden(true)
            } else {
                Spacer(minLength: 50)
            }

            Text(message.text)
                .font(.body)
                .foregroundStyle(message.isFromDino ? Color.primary : Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(message.isFromDino ? Color(uiColor: .secondarySystemGroupedBackground) : Color(red: 0.04, green: 0.43, blue: 0.36))
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                .frame(maxWidth: 520, alignment: message.isFromDino ? .leading : .trailing)

            if message.isFromDino {
                Spacer(minLength: 50)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DinoChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromDino: Bool
}

@MainActor
private final class DinoChatViewModel: ObservableObject {
    @Published var draft = ""
    @Published var messages: [DinoChatMessage] = [
        DinoChatMessage(
            text: "Hi, I'm Dino Munch. Ask me a family money question about saving, spending, allowance, needs versus wants, or Market Lab.",
            isFromDino: true
        )
    ]
    @Published var isSending = false
    @Published var isShowingError = false
    @Published var errorMessage = "Please try again in a moment."

    private let service = DinoChatService()
    private let threadKey = "moneymuncher.dino.threadId"

    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    func sendDraft() {
        send(draft)
    }

    func send(_ rawText: String) {
        let text = String(rawText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(700))
        guard !text.isEmpty, !isSending else { return }

        draft = ""
        messages.append(DinoChatMessage(text: text, isFromDino: false))
        isSending = true

        Task {
            do {
                let response = try await service.send(
                    message: text,
                    threadID: UserDefaults.standard.string(forKey: threadKey)
                )
                if let threadID = response.threadId, !threadID.isEmpty {
                    UserDefaults.standard.set(threadID, forKey: threadKey)
                }
                messages.append(DinoChatMessage(text: response.reply, isFromDino: true))
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
            isSending = false
        }
    }

    func startNewChat() {
        UserDefaults.standard.removeObject(forKey: threadKey)
        draft = ""
        messages = [
            DinoChatMessage(
                text: "New chat started. What money question can I help your family explore?",
                isFromDino: true
            )
        ]
    }
}

private struct DinoChatService {
    private let endpoint = URL(string: "https://www.moneymuncher.ca/.netlify/functions/chat")!

    func send(message: String, threadID: String?) async throws -> DinoChatResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 35
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            DinoChatRequest(
                message: message,
                threadId: threadID,
                page: DinoChatPage(title: "Money Muncher iOS", path: "/ios/dino-chat")
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DinoChatError.invalidResponse
        }

        if (200..<300).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(DinoChatResponse.self, from: data)
        }

        let serverError = try? JSONDecoder().decode(DinoChatServerError.self, from: data)
        throw DinoChatError.server(serverError?.error ?? "Dino Chat is unavailable right now.")
    }
}

private struct DinoChatRequest: Encodable {
    let message: String
    let threadId: String?
    let page: DinoChatPage
}

private struct DinoChatPage: Encodable {
    let title: String
    let path: String
}

private struct DinoChatResponse: Decodable {
    let reply: String
    let threadId: String?
}

private struct DinoChatServerError: Decodable {
    let error: String
}

private enum DinoChatError: LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Dino Chat returned an unexpected response."
        case .server(let message):
            return message
        }
    }
}
