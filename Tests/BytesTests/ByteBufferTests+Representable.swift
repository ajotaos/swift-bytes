import XCTest

@testable import Bytes

final class ByteBufferTests_Representable: XCTestCase {
    func testInitializeWithRepresentableValue() {
        let buffer = ByteBuffer(value: UInt32(0x0001_0203), endianness: .big)

        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 4)

        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [0, 1, 2, 3])
    }

    func testInitializeWithRepresentableValues() {
        let buffer = ByteBuffer(
            values: [UInt32(0x0001_0203), UInt32(0x0001_0203)], endianness: .big)

        XCTAssertEqual(buffer.count, 8)
        XCTAssertEqual(buffer.capacity, 8)

        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [0, 1, 2, 3, 0, 1, 2, 3])
    }

    func testReadRepresentableValue() {
        let buffer = ByteBuffer(value: UInt64(0x0001_0203_0001_0203), endianness: .big)

        XCTAssertEqual(
            buffer.readRepresentableValue(fromByteOffset: 0, endianness: .big, as: UInt32.self),
            0x0001_0203)
        XCTAssertEqual(
            buffer.readRepresentableValue(fromByteOffset: 4, endianness: .little, as: UInt32.self),
            0x0302_0100)
    }

    func testReadRepresentableValues() {
        let buffer = ByteBuffer(
            values: [UInt64(0x0001_0203_0001_0203), UInt64(0x0001_0203_0001_0203)], endianness: .big
        )

        XCTAssertEqual(
            Array(
                buffer.readRepresentableValues(
                    fromByteOffset: 0, count: 2, endianness: .big, as: UInt32.self)),
            [0x0001_0203, 0x0001_0203])
        XCTAssertEqual(
            Array(
                buffer.readRepresentableValues(
                    fromByteOffset: 8, count: 2, endianness: .little, as: UInt32.self)),
            [0x0302_0100, 0x0302_0100])
    }

    func testWriteRepresentableValue() {
        var buffer = ByteBuffer()

        XCTAssertEqual(
            buffer.writeRepresentableValue(UInt32(0x0001_0203), toByteOffset: 0, endianness: .big),
            4)

        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 6)

        XCTAssertEqual(
            buffer.writeRepresentableValue(
                UInt32(0x0001_0203), toByteOffset: 4, endianness: .little), 4)

        XCTAssertEqual(buffer.count, 8)
        XCTAssertEqual(buffer.capacity, 12)

        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [0, 1, 2, 3, 3, 2, 1, 0])
    }

    func testWriteRepresentableValues() {
        var buffer = ByteBuffer()

        XCTAssertEqual(
            buffer.writeRepresentableValues(
                [UInt32(0x0001_0203), UInt32(0x0001_0203)], toByteOffset: 0, endianness: .big), 8)

        XCTAssertEqual(buffer.count, 8)
        XCTAssertEqual(buffer.capacity, 12)

        XCTAssertEqual(
            buffer.writeRepresentableValues(
                [UInt32(0x0001_0203), UInt32(0x0001_0203)], toByteOffset: 8, endianness: .little), 8
        )

        XCTAssertEqual(buffer.count, 16)
        XCTAssertEqual(buffer.capacity, 24)

        XCTAssertEqual(
            buffer.withUnsafeBytes(Array.init), [0, 1, 2, 3, 0, 1, 2, 3, 3, 2, 1, 0, 3, 2, 1, 0])
    }
}
