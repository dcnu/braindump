import SwiftUI

struct ContentView: View {
	var body: some View {
		VStack(spacing: 0) {
			Text("Braindump")
				.font(.system(.body, design: .monospaced))
				.foregroundStyle(.secondary)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
		.frame(minWidth: 300, minHeight: 200)
	}
}
