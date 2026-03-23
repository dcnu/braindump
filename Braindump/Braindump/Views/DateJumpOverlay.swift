import SwiftUI

struct DateJumpOverlay: View {
	@Binding var query: String
	let dayStartHour: Int
	let hasNotes: (String) -> Bool
	let onJump: (String) -> Void
	let onDismiss: () -> Void

	@FocusState private var isFocused: Bool

	private var parsedDate: String? {
		DateParser.parse(query, dayStartHour: dayStartHour)
	}

	private var logicalToday: String {
		DateFormatting.logicalDate(dayStartHour: dayStartHour)
	}

	private var isFutureDate: Bool {
		guard let date = parsedDate else { return false }
		return date > logicalToday
	}

	private var suggestion: String? {
		DateParser.suggestions(for: query).first
	}

	private var canJump: Bool {
		parsedDate != nil && !isFutureDate
	}

	var body: some View {
		VStack(spacing: 12) {
			Text("Jump to Date")
				.font(.system(.title3, design: .monospaced, weight: .bold))
				.frame(maxWidth: .infinity, alignment: .leading)

			ZStack(alignment: .leading) {
				// Suggestion ghost text
				if let suggestion, !query.isEmpty, suggestion != query.lowercased() {
					Text(suggestion)
						.font(.system(.body, design: .monospaced))
						.foregroundStyle(.quaternary)
						.padding(.horizontal, 6)
						.padding(.vertical, 4)
				}

				TextField("today, yesterday, last monday...", text: $query)
					.font(.system(.body, design: .monospaced))
					.textFieldStyle(.roundedBorder)
					.focused($isFocused)
					.onSubmit {
						if canJump, let date = parsedDate {
							onJump(date)
						}
					}
					.onKeyPress(.tab) {
						if let suggestion {
							query = suggestion
							return .handled
						}
						return .ignored
					}
					.onKeyPress(.rightArrow) {
						if let suggestion, query.count < suggestion.count {
							query = suggestion
							return .handled
						}
						return .ignored
					}
			}

			// Status
			if !query.isEmpty {
				HStack {
					if let date = parsedDate {
						if isFutureDate {
							Image(systemName: "xmark.circle.fill")
								.foregroundStyle(.red)
							Text("Cannot jump to future dates")
								.font(.system(.body, design: .monospaced))
								.foregroundStyle(.red)
						} else {
							Image(systemName: "checkmark.circle.fill")
								.foregroundStyle(.green)
							Text(DateFormatting.displayDate(date))
								.font(.system(.body, design: .monospaced))

							if !hasNotes(date) && date != logicalToday {
								Text("(no notes)")
									.font(.system(.caption, design: .monospaced))
									.foregroundStyle(.orange)
							}
						}
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
				Text("Tab to autocomplete. Esc to close.")
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
