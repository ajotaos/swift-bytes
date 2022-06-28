import XCTest

@testable import Bytes

final class ByteBufferTests_String: XCTestCase {
    func testInitializeWithString() {
        let buffer = ByteBuffer(string: "abcd")

        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 4)

        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [97, 98, 99, 100])
    }

    func testReadString() {
        let buffer = ByteBuffer(string: "abcddcba")

        XCTAssertEqual(buffer.readString(fromByteOffset: 0, byteCount: 4), "abcd")
        XCTAssertEqual(buffer.readString(fromByteOffset: 4, byteCount: 4), "dcba")
    }

    func testWriteString() {
        var buffer = ByteBuffer()

        XCTAssertEqual(buffer.writeString("abcd", toByteOffset: 0), 4)

        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 6)

        XCTAssertEqual(buffer.writeString("dcba", toByteOffset: 4), 4)

        XCTAssertEqual(buffer.capacity, 12)
        XCTAssertEqual(buffer.count, 8)

        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [97, 98, 99, 100, 100, 99, 98, 97])
    }
}
