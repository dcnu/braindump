import SwiftUI
import AppKit

struct AutoClosingTextEditor: NSViewRepresentable {
	@Binding var text: String
	var onSubmit: (() -> Void)?
	var isEditable: Bool = true
	var autoCorrect: Bool = false
	var shouldFocus: Bool = false
	var fontColorHex: String = "#000000"

	func makeNSView(context: Context) -> IntrinsicScrollView {
		let scrollView = IntrinsicScrollView()
		scrollView.hasVerticalScroller = false
		scrollView.hasHorizontalScroller = false
		scrollView.drawsBackground = false
		scrollView.borderType = .noBorder

		let textView = BraindumpTextView()
		textView.isEditable = isEditable
		textView.drawsBackground = false
		textView.string = text
		textView.isAutomaticSpellingCorrectionEnabled = autoCorrect
		textView.autoresizingMask = [.width]
		textView.isVerticallyResizable = true
		textView.isHorizontallyResizable = false

		textView.minSize = NSSize(width: 0, height: 0)
		textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

		textView.onTextChange = { newText in
			Task { @MainActor in
				context.coordinator.isUpdating = true
				self.text = newText
				context.coordinator.isUpdating = false
				scrollView.invalidateIntrinsicContentSize()
			}
		}

		textView.onSubmit = {
			onSubmit?()
		}

		scrollView.documentView = textView
		context.coordinator.textView = textView
		context.coordinator.scrollView = scrollView

		return scrollView
	}

	func updateNSView(_ nsView: IntrinsicScrollView, context: Context) {
		guard let textView = context.coordinator.textView else { return }
		guard !context.coordinator.isUpdating else { return }

		if textView.string != text {
			let cursorPos = textView.selectedRange().location
			textView.string = text
			if let storage = textView.textStorage {
				textView.markdownHighlighter.applyHighlighting(to: storage)
			}
			let safeCursor = min(cursorPos, textView.string.count)
			textView.setSelectedRange(NSRange(location: safeCursor, length: 0))
		}

		textView.isEditable = isEditable
		textView.isAutomaticSpellingCorrectionEnabled = autoCorrect

		let hex = fontColorHex
		textView.textColor = NSColor(
			red: CGFloat(Int(hex.dropFirst().prefix(2), radix: 16) ?? 0) / 255,
			green: CGFloat(Int(hex.dropFirst(3).prefix(2), radix: 16) ?? 0) / 255,
			blue: CGFloat(Int(hex.dropFirst(5).prefix(2), radix: 16) ?? 0) / 255,
			alpha: 1
		)

		if let scrollWidth = textView.enclosingScrollView?.contentSize.width, scrollWidth > 0 {
			textView.frame.size.width = scrollWidth
			textView.textContainer?.containerSize = NSSize(width: scrollWidth, height: CGFloat.greatestFiniteMagnitude)
		}

		nsView.invalidateIntrinsicContentSize()

		if shouldFocus && !context.coordinator.didFocus {
			context.coordinator.didFocus = true
			DispatchQueue.main.async {
				textView.window?.makeFirstResponder(textView)
			}
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator()
	}

	final class Coordinator {
		var textView: BraindumpTextView?
		var scrollView: IntrinsicScrollView?
		var isUpdating = false
		var didFocus = false
	}
}

/// NSScrollView subclass that reports its document view's height as intrinsic content size.
/// This tells SwiftUI how much vertical space the editor needs.
final class IntrinsicScrollView: NSScrollView {
	override var intrinsicContentSize: NSSize {
		guard let docView = documentView else {
			return NSSize(width: NSView.noIntrinsicMetric, height: 24)
		}
		// Use the layout manager's used rect for accurate height
		if let textView = docView as? NSTextView,
		   let layoutManager = textView.layoutManager,
		   let textContainer = textView.textContainer {
			layoutManager.ensureLayout(for: textContainer)
			let usedRect = layoutManager.usedRect(for: textContainer)
			return NSSize(width: NSView.noIntrinsicMetric, height: max(24, usedRect.height + 8))
		}
		return NSSize(width: NSView.noIntrinsicMetric, height: max(24, docView.frame.height))
	}
}
