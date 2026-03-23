import Foundation

enum MathEvaluator {
	/// Process lines in a math block. Evaluates expressions ending with `=`.
	/// Handles variable assignments like `x = 10` and expressions like `x * 5 =`.
	static func evaluate(_ lines: [String]) -> [String] {
		var variables: [String: Double] = [:]
		var result: [String] = []

		for line in lines {
			let trimmed = line.trimmingCharacters(in: .whitespaces)

			// Skip empty lines
			guard !trimmed.isEmpty else {
				result.append(line)
				continue
			}

			// Variable assignment: `name = expression`
			if let match = trimmed.range(of: #"^([a-zA-Z_]\w*)\s*=\s*(.+)$"#, options: .regularExpression) {
				let fullMatch = String(trimmed[match])
				let parts = fullMatch.components(separatedBy: "=")
				if parts.count >= 2 {
					let name = parts[0].trimmingCharacters(in: .whitespaces)
					let expr = parts[1...].joined(separator: "=").trimmingCharacters(in: .whitespaces)

					if let value = evaluateExpression(expr, variables: variables) {
						variables[name] = value
						result.append(line)
					} else {
						result.append(line)
					}
				}
				continue
			}

			// Expression ending with `=`: evaluate and append result
			if trimmed.hasSuffix("=") {
				let expr = String(trimmed.dropLast()).trimmingCharacters(in: .whitespaces)
				if let value = evaluateExpression(expr, variables: variables) {
					let formatted = formatNumber(value)
					result.append("\(trimmed) \(formatted)")
				} else {
					result.append(line)
				}
				continue
			}

			result.append(line)
		}

		return result
	}

	/// Detect if content contains a math block trigger keyword.
	static func containsMathBlock(_ content: String) -> Bool {
		let lines = content.components(separatedBy: "\n")
		return lines.contains { line in
			let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
			return trimmed == "math" || trimmed == "estimate" || trimmed == "calculate"
				|| trimmed == "```math"
		}
	}

	/// Process content: find math blocks and evaluate them.
	static func processContent(_ content: String) -> String {
		let lines = content.components(separatedBy: "\n")
		var result: [String] = []
		var inMathBlock = false
		var mathLines: [String] = []

		for line in lines {
			let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

			if !inMathBlock && (trimmed == "math" || trimmed == "estimate" || trimmed == "calculate" || trimmed == "```math") {
				inMathBlock = true
				result.append(line)
				continue
			}

			if inMathBlock {
				if trimmed.isEmpty || trimmed == "```" {
					// End of math block — evaluate accumulated lines
					let evaluated = evaluate(mathLines)
					result.append(contentsOf: evaluated)
					mathLines = []
					inMathBlock = false
					result.append(line)
				} else {
					mathLines.append(line)
				}
			} else {
				result.append(line)
			}
		}

		// Handle math block at end of content
		if !mathLines.isEmpty {
			let evaluated = evaluate(mathLines)
			result.append(contentsOf: evaluated)
		}

		return result.joined(separator: "\n")
	}

	// MARK: - Recursive Descent Parser

	private static func evaluateExpression(_ input: String, variables: [String: Double]) -> Double? {
		var tokens = tokenize(input, variables: variables)
		var index = 0
		let result = parseAddSub(&tokens, &index)
		return index == tokens.count ? result : nil
	}

	private enum Token {
		case number(Double)
		case op(Character)
		case lparen
		case rparen
	}

	private static func tokenize(_ input: String, variables: [String: Double]) -> [Token] {
		var tokens: [Token] = []
		var chars = Array(input)
		var i = 0

		while i < chars.count {
			let ch = chars[i]

			if ch.isWhitespace {
				i += 1
				continue
			}

			if ch.isNumber || ch == "." {
				var numStr = String(ch)
				i += 1
				while i < chars.count && (chars[i].isNumber || chars[i] == ".") {
					numStr.append(chars[i])
					i += 1
				}
				if let num = Double(numStr) {
					tokens.append(.number(num))
				}
				continue
			}

			if ch.isLetter || ch == "_" {
				var name = String(ch)
				i += 1
				while i < chars.count && (chars[i].isLetter || chars[i].isNumber || chars[i] == "_") {
					name.append(chars[i])
					i += 1
				}
				if let value = variables[name] {
					tokens.append(.number(value))
				}
				continue
			}

			if "+-*/".contains(ch) {
				tokens.append(.op(ch))
				i += 1
				continue
			}

			if ch == "(" {
				tokens.append(.lparen)
				i += 1
				continue
			}

			if ch == ")" {
				tokens.append(.rparen)
				i += 1
				continue
			}

			i += 1
		}

		return tokens
	}

	private static func parseAddSub(_ tokens: inout [Token], _ index: inout Int) -> Double? {
		guard var left = parseMulDiv(&tokens, &index) else { return nil }

		while index < tokens.count {
			if case .op(let op) = tokens[index], op == "+" || op == "-" {
				index += 1
				guard let right = parseMulDiv(&tokens, &index) else { return nil }
				left = op == "+" ? left + right : left - right
			} else {
				break
			}
		}

		return left
	}

	private static func parseMulDiv(_ tokens: inout [Token], _ index: inout Int) -> Double? {
		guard var left = parseAtom(&tokens, &index) else { return nil }

		while index < tokens.count {
			if case .op(let op) = tokens[index], op == "*" || op == "/" {
				index += 1
				guard let right = parseAtom(&tokens, &index) else { return nil }
				if op == "/" && right == 0 { return nil }
				left = op == "*" ? left * right : left / right
			} else {
				break
			}
		}

		return left
	}

	private static func parseAtom(_ tokens: inout [Token], _ index: inout Int) -> Double? {
		guard index < tokens.count else { return nil }

		// Unary minus
		if case .op(let op) = tokens[index], op == "-" {
			index += 1
			guard let value = parseAtom(&tokens, &index) else { return nil }
			return -value
		}

		if case .number(let n) = tokens[index] {
			index += 1
			return n
		}

		if case .lparen = tokens[index] {
			index += 1
			let value = parseAddSub(&tokens, &index)
			if index < tokens.count, case .rparen = tokens[index] {
				index += 1
			}
			return value
		}

		return nil
	}

	private static func formatNumber(_ value: Double) -> String {
		if value == value.rounded() && abs(value) < 1e15 {
			return String(format: "%.0f", value)
		}
		return String(format: "%.2f", value)
	}
}
