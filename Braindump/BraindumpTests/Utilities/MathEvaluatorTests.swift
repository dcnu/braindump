import XCTest
@testable import Braindump

final class MathEvaluatorTests: XCTestCase {
	func testBasicAddition() {
		let result = MathEvaluator.evaluate(["2 + 3 ="])
		XCTAssertEqual(result, ["2 + 3 = 5"])
	}

	func testBasicSubtraction() {
		let result = MathEvaluator.evaluate(["10 - 4 ="])
		XCTAssertEqual(result, ["10 - 4 = 6"])
	}

	func testMultiplication() {
		let result = MathEvaluator.evaluate(["6 * 7 ="])
		XCTAssertEqual(result, ["6 * 7 = 42"])
	}

	func testDivision() {
		let result = MathEvaluator.evaluate(["100 / 4 ="])
		XCTAssertEqual(result, ["100 / 4 = 25"])
	}

	func testParentheses() {
		let result = MathEvaluator.evaluate(["(2 + 3) * 4 ="])
		XCTAssertEqual(result, ["(2 + 3) * 4 = 20"])
	}

	func testVariableAssignment() {
		let result = MathEvaluator.evaluate([
			"x = 10",
			"x * 5 =",
		])
		XCTAssertEqual(result[0], "x = 10")
		XCTAssertEqual(result[1], "x * 5 = 50")
	}

	func testMultipleVariables() {
		let result = MathEvaluator.evaluate([
			"attendees = 10",
			"total = 100",
			"total / attendees =",
		])
		XCTAssertEqual(result[2], "total / attendees = 10")
	}

	func testDivisionByZero() {
		let result = MathEvaluator.evaluate(["10 / 0 ="])
		XCTAssertEqual(result, ["10 / 0 ="])
	}

	func testDecimalResult() {
		let result = MathEvaluator.evaluate(["10 / 3 ="])
		XCTAssertEqual(result, ["10 / 3 = 3.33"])
	}

	func testUnaryMinus() {
		let result = MathEvaluator.evaluate(["-5 + 3 ="])
		XCTAssertEqual(result, ["-5 + 3 = -2"])
	}

	func testEmptyLines() {
		let result = MathEvaluator.evaluate(["", "2 + 2 =", ""])
		XCTAssertEqual(result, ["", "2 + 2 = 4", ""])
	}

	func testNoTrailingEquals() {
		let result = MathEvaluator.evaluate(["2 + 2"])
		XCTAssertEqual(result, ["2 + 2"])
	}

	func testContainsMathBlock() {
		XCTAssertTrue(MathEvaluator.containsMathBlock("math\nx = 10"))
		XCTAssertTrue(MathEvaluator.containsMathBlock("calculate\n5 + 5 ="))
		XCTAssertTrue(MathEvaluator.containsMathBlock("estimate\ncost = 100"))
		XCTAssertFalse(MathEvaluator.containsMathBlock("just some text"))
	}

	func testProcessContent() {
		let input = "math\nx = 10\nx * 5 ="
		let result = MathEvaluator.processContent(input)
		XCTAssertTrue(result.contains("x * 5 = 50"))
	}
}
