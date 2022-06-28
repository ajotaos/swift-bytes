import XCTest

@testable import Bytes

final class CalculateGrownCapacityTests: XCTestCase {
    func testCalculateGrowthForCapacityOfZero() {
        XCTAssertEqual(calculateGrownCapacity(for: 0), 2)
    }

    func testCalculateGrowthForCapacityOfOne() {
        XCTAssertEqual(calculateGrownCapacity(for: 1), 2)
    }

    func testCalculateGrowthForCapacityOfPowersOfTwo() {
        XCTAssertEqual(
            [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048].map(calculateGrownCapacity(for:)),
            [4, 6, 12, 24, 48, 96, 192, 384, 768, 1536, 3072])
    }

    func testCalculateGrowthForCapacityOfHalfOfMax() {
        XCTAssertEqual(calculateGrownCapacity(for: .max / 2), .max >> 1 + .max >> 2)
    }

    func testCalculateGrowthForCapacityOfTwoThirdsOfMax() {
        XCTAssertEqual(calculateGrownCapacity(for: .max / 3 * 2), .max - 1)
    }

    func testCalculateGrowthForCapacityOfTwoThirdsOfMaxPlusOne() {
        XCTAssertEqual(calculateGrownCapacity(for: .max / 3 * 2 + 1), .max)
    }

    func testCalculateGrowthForCapacityOfMax() {
        XCTAssertEqual(calculateGrownCapacity(for: .max), .max)
    }
}
