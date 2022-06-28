import XCTest

@testable import Bytes

final class ByteBufferTests: XCTestCase {
    func testInitialize() {
        let buffer = ByteBuffer()

        XCTAssertEqual(buffer.count, 0)
        XCTAssertEqual(buffer.capacity, 0)
    }

    func testInitializeWithBytes() {
        let buffer = ByteBuffer(bytes: [0, 1, 2, 3])

        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 4)

        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [0, 1, 2, 3])
    }

    func testInitializeWithBuffer() {
        let mutableBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)

        mutableBuffer.copyBytes(from: [0, 1, 2, 3])

        let buffer = ByteBuffer(bytes: .init(mutableBuffer))

        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 4)

        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [0, 1, 2, 3])
    }

    func testInitializeWithUnsafeUninitializedCapacityAndInitializer() {
        let mutableBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)

        mutableBuffer.copyBytes(from: [0, 1, 2, 3])

        let buffer = ByteBuffer(
            unsafeUninitializedCapacity: mutableBuffer.count,
            initializingWith: {
                $0.copyMemory(from: .init(mutableBuffer))

                return mutableBuffer.count
            })

        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 4)

        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [0, 1, 2, 3])
    }

    func testReserveMinimumCapacity() {
        var buffer = ByteBuffer()

        buffer.reserveCapacity(8)

        XCTAssertEqual(buffer.count, 0)
        XCTAssertEqual(buffer.capacity, 12)
    }

    func testReadBytes() {
        let buffer = ByteBuffer(bytes: [0, 1, 2, 3, 3, 2, 1, 0])

        XCTAssertEqual(Array(buffer.readBytes(fromByteOffset: 0, byteCount: 4)), [0, 1, 2, 3])
        XCTAssertEqual(Array(buffer.readBytes(fromByteOffset: 4, byteCount: 4)), [3, 2, 1, 0])
    }

    func testWriteBytes() {
        var buffer = ByteBuffer()

        XCTAssertEqual(buffer.writeBytes([0, 1, 2, 3], toByteOffset: 0), 4)

        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 6)

        let mutableBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)

        mutableBuffer.copyBytes(from: [3, 2, 1, 0])

        XCTAssertEqual(buffer.writeBytes(.init(mutableBuffer), toByteOffset: 4), 4)

        XCTAssertEqual(buffer.count, 8)
        XCTAssertEqual(buffer.capacity, 12)

        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [0, 1, 2, 3, 3, 2, 1, 0])
    }

    func testWithUnsafeBytes() {
        let buffer = ByteBuffer(bytes: [0, 1, 2, 3, 3, 2, 1, 0])

        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [0, 1, 2, 3, 3, 2, 1, 0])
    }

    func testWithUnsafeMutableBytes() {
        var buffer = ByteBuffer(bytes: [0, 1, 2, 3, 3, 2, 1, 0])

        XCTAssertEqual(buffer.withUnsafeMutableBytes(Array.init), [0, 1, 2, 3, 3, 2, 1, 0])
    }

    func testEquatableConformance() {
        let buffer1 = ByteBuffer(bytes: [2, 3, 3, 2, 1])
        let buffer2 = ByteBuffer(bytes: [2, 3, 3, 2, 1])

        XCTAssertTrue(buffer1 == buffer2)
    }

    func testEncodableConformance() throws {
        let buffer = ByteBuffer(bytes: [0, 1, 2, 3])

        let encoder = JSONEncoder()

        try XCTAssertEqual(encoder.encode(buffer), encoder.encode([0, 1, 2, 3]))
    }

    func testDecodableConformance() throws {
        let encoder = JSONEncoder()

        let data = try encoder.encode([0, 1, 2, 3])

        let decoder = JSONDecoder()

        try XCTAssertEqual(
            decoder.decode(ByteBuffer.self, from: data), ByteBuffer(bytes: [0, 1, 2, 3]))
    }
}
