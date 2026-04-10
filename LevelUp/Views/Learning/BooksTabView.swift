//
//  BooksTabView.swift
//  LEVEL UP — Phase 2
//
//  Track books. Log pages read, mark finished. Finishing grants
//  +200 XP.
//

import SwiftUI
import SwiftData

struct BooksTabView: View {

    let user: User
    let vm: LearningViewModel

    @Environment(\.modelContext) private var context

    @State private var showingAdd = false
    @State private var newTitle: String = ""
    @State private var newAuthor: String = ""
    @State private var newCategory: String = "Finance"
    @State private var newPages: String = "300"

    // Per-row "pages to add" drafts (id → text). Uses a sidecar dict
    // so we don't mutate the SwiftData row until the user hits log.
    @State private var pageDrafts: [UUID: String] = [:]

    private let categories = ["Finance", "Business", "Biography", "Self Development", "Other"]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Button {
                    resetForm()
                    showingAdd = true
                } label: {
                    Label("Add Book", systemImage: "plus.circle.fill")
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Theme.primaryAccent.opacity(0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.primaryAccent.opacity(0.55), lineWidth: 1)
                        )
                        .foregroundStyle(Theme.primaryAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                Spacer()
            }

            readingCard
            finishedCard
        }
        .sheet(isPresented: $showingAdd) { addSheet }
    }

    // MARK: - Reading

    private var readingCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("READING")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)
                if vm.booksInProgress.isEmpty {
                    Text("No books in progress.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(vm.booksInProgress) { book in
                        bookRow(book)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func bookRow(_ book: Book) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(.headline).fontWeight(.bold)
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(book.author) · \(book.category)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text("\(book.pagesRead) / \(book.totalPages) pages")
                    .font(.subheadline).monospacedDigit().fontWeight(.heavy)
                    .foregroundStyle(Theme.primaryAccent)
            }
            ProgressBar(progress: book.progress, color: Theme.primaryAccent)
            HStack(spacing: 8) {
                TextField("Pages read",
                          text: Binding(
                            get: { pageDrafts[book.id] ?? "" },
                            set: { pageDrafts[book.id] = $0 }))
                    .textFieldStyle(.plain)
                    .frame(width: 120)
                    .padding(8)
                    .background(Theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.cardBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Button("Log Pages") { logPages(book) }
                    .buttonStyle(.bordered)
                    .tint(Theme.primaryAccent)
                Spacer()
                Button("Mark Finished") { finish(book) }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.xpGreen)
                    .foregroundStyle(Color.black)
            }
            .font(.caption)
        }
        .padding(12)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Finished

    private var finishedCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text("FINISHED")
                    .font(.caption).fontWeight(.heavy).tracking(2)
                    .foregroundStyle(Theme.textSecondary)
                if vm.finishedBooks.isEmpty {
                    Text("None yet.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    ForEach(vm.finishedBooks) { b in
                        HStack {
                            Image(systemName: "book.closed.fill")
                                .foregroundStyle(Theme.xpGreen)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(b.title)
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundStyle(Theme.textPrimary)
                                Text(b.author)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Text("+\(b.xpEarned) XP")
                                .font(.caption).fontWeight(.heavy)
                                .foregroundStyle(Theme.xpGreen)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Add sheet

    private var addSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("NEW BOOK")
                .font(.title2).fontWeight(.black).tracking(3)
                .foregroundStyle(Theme.textPrimary)

            field("Title", text: $newTitle)
            field("Author", text: $newAuthor)
            Picker("Category", selection: $newCategory) {
                ForEach(categories, id: \.self) { Text($0) }
            }
            field("Total pages", text: $newPages)

            HStack {
                Button("Cancel") { showingAdd = false }
                Spacer()
                Button("Add", action: addBook)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.primaryAccent)
                    .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty
                              || Int(newPages) == nil)
            }
        }
        .padding(32)
        .frame(minWidth: 380, minHeight: 380)
        .background(Theme.background)
    }

    private func field(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
            TextField(label, text: text)
                .textFieldStyle(.plain)
                .padding(10)
                .background(Theme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    // MARK: - Actions

    private func resetForm() {
        newTitle = ""
        newAuthor = ""
        newCategory = "Finance"
        newPages = "300"
    }

    private func addBook() {
        guard let pages = Int(newPages) else { return }
        let book = Book(title: newTitle.trimmingCharacters(in: .whitespaces),
                        author: newAuthor,
                        category: newCategory,
                        totalPages: pages)
        context.insert(book)
        try? context.save()
        showingAdd = false
    }

    private func logPages(_ book: Book) {
        guard let added = Int(pageDrafts[book.id] ?? ""), added > 0 else { return }
        book.pagesRead = min(book.totalPages, book.pagesRead + added)
        // 30 XP per page-logging session (reading is precious).
        let xp = 30
        book.xpEarned += xp
        user.award(xp, to: .learning)
        pageDrafts[book.id] = ""
        try? context.save()
        evaluate()
    }

    private func finish(_ book: Book) {
        guard !book.isFinished else { return }
        book.isFinished = true
        book.finishedAt = .now
        book.pagesRead = book.totalPages
        book.xpEarned += XPEngine.xpForBookFinished
        user.award(XPEngine.xpForBookFinished, to: .learning)
        try? context.save()
        evaluate()
    }

    private func evaluate() {
        let newly = UnlockEngine.evaluateUnlocks(user: user, context: context)
        UnlockCenter.shared.present(newly)
    }
}
