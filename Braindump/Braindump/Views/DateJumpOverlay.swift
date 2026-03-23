import SwiftUI

struct DateJumpOverlay: View {
	@Binding var query: String
	let dayStartHour: Int
	let onJump: (String) -> Void
	let onDismiss: () -> Void

	@FocusState private var isFocused: Bool

	private var parsedDate: String? {
		DateParser.parse(query, dayStartHour: dayStartHour)
	}

	var body: some View {
		VStack(spacing: 12) {
			HStack {
				Text("Jump to Date")
					.font(.system(.title3, design: .monospaced, weight: .bold))
				Spacer()
				Button {
					onDismiss()
				} label: {
					Image(systemName: "xmark.circle.fill")
						.foregroundStyle(.secondary)
						.font(.title3)
				}
				.buttonStyle(.plain)
			}

			TextField("today, yesterday, last monday, march 21...", text: $query)
				.font(.system(.body, design: .monospaced))
				.textFieldStyle(.roundedBorder)
				.focused($isFocused)
				.onSubmit {
					if let date = parsedDate {
						onJump(date)
					}
				}

			if !query.isEmpty {
				HStack {
					if let date = parsedDate {
						Image(systemName: "checkmark.circle.fill")
							.foregroundStyle(.green)
						Text(DateFormatting.displayDate(date))
							.font(.system(.body, design: .monospaced))
						Text("(\(date))")
							.font(.system(.caption, design: .monospaced))
							.foregroundStyle(.secondary)
					} else {
						Image(systemName: "questionmark.circle")
							.foregroundStyle(.orange)
						Text("Could not parse date")
							.font(.system(.body, design: .monospaced))
							.foregroundStyle(.secondary)
					}
					Spacer()
				}
			}

			HStack {
				Text("Try: today, yesterday, 3 days ago, last friday, march 21, 2026-03-21")
					.font(.caption)
					.foregroundStyle(.tertiary)
				Spacer()
			}
		}
		.padding(24)
		.background(
			RoundedRectangle(cornerRadius: 12)
				.fill(.ultraThickMaterial)
				.shadow(radius: 20)
		)
		.frame(maxWidth: 420)
		.onAppear {
			isFocused = true
		}
	}
}
