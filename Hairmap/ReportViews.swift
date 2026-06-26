import SwiftUI

struct ReportDraft: Identifiable, Hashable {
    let id = UUID()
    let entityType: ReportEntityType
    let entityID: String
    let title: String
    var subtitle: String = ""
}

struct ReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let draft: ReportDraft
    let onSubmit: (String, String) -> Void

    @State private var selectedReason = "不當或冒犯內容"
    @State private var details = ""

    private let reasons = [
        "不當或冒犯內容",
        "虛假資料或冒充",
        "騷擾、垃圾訊息",
        "侵犯私隱或肖像",
        "其他"
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(draft.title)
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.black)
                    if !draft.subtitle.isEmpty {
                        Text(draft.subtitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("檢舉原因")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                        ForEach(reasons, id: \.self) { reason in
                            Button {
                                selectedReason = reason
                            } label: {
                                HStack(spacing: 7) {
                                    Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                                    Text(reason)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.76)
                                }
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(selectedReason == reason ? .black : .secondary)
                                .padding(.horizontal, 10)
                                .frame(height: 38)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(selectedReason == reason ? Color.yellow.opacity(0.18) : Color.gray.opacity(0.08), in: Capsule())
                                .overlay(Capsule().stroke(selectedReason == reason ? Color.yellow.opacity(0.55) : Color.black.opacity(0.08), lineWidth: 1))
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("補充說明（選填）")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.secondary)
                    TextEditor(text: $details)
                        .font(.system(size: 14, weight: .medium))
                        .frame(height: 116)
                        .padding(10)
                        .scrollContentBackground(.hidden)
                        .background(Color(red: 0.97, green: 0.975, blue: 0.985), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.black.opacity(0.16), lineWidth: 1))
                }

                Spacer(minLength: 0)

                Button {
                    onSubmit(selectedReason, details.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                } label: {
                    Text("送出檢舉")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.black, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(20)
            .navigationTitle("檢舉內容")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(24)
        .preferredColorScheme(.light)
    }
}
