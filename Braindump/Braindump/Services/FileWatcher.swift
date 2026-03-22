import Foundation

final class FileWatcher {
	private let directoryURL: URL
	private let onChange: () -> Void
	private var source: DispatchSourceFileSystemObject?
	private var fileDescriptor: Int32 = -1
	private let queue = DispatchQueue(label: "com.dcnu.braindump.filewatcher", qos: .utility)
	private var debounceWorkItem: DispatchWorkItem?

	init(directoryURL: URL, onChange: @escaping () -> Void) {
		self.directoryURL = directoryURL
		self.onChange = onChange
	}

	deinit {
		stop()
	}

	func start() {
		stop()

		fileDescriptor = open(directoryURL.path, O_EVTONLY)
		guard fileDescriptor >= 0 else { return }

		source = DispatchSource.makeFileSystemObjectSource(
			fileDescriptor: fileDescriptor,
			eventMask: [.write, .rename, .delete],
			queue: queue
		)

		source?.setEventHandler { [weak self] in
			self?.handleEvent()
		}

		source?.setCancelHandler { [weak self] in
			guard let self, self.fileDescriptor >= 0 else { return }
			close(self.fileDescriptor)
			self.fileDescriptor = -1
		}

		source?.resume()
	}

	func stop() {
		debounceWorkItem?.cancel()
		debounceWorkItem = nil

		if let source {
			source.cancel()
			self.source = nil
		} else if fileDescriptor >= 0 {
			close(fileDescriptor)
			fileDescriptor = -1
		}
	}

	private func handleEvent() {
		debounceWorkItem?.cancel()

		let workItem = DispatchWorkItem { [weak self] in
			DispatchQueue.main.async {
				self?.onChange()
			}
		}

		debounceWorkItem = workItem
		queue.asyncAfter(
			deadline: .now() + Constants.fileWatcherDebounce,
			execute: workItem
		)
	}
}
