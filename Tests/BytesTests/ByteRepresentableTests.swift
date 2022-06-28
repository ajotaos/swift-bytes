import XCTest

@testable import Bytes

final class ByteRepresentableTests: XCTestCase {
    func testUnsignedFixedWidthInteger() {
        let value: UInt = 128

        let bigEndianBytes = value.withUnsafeBytes(endianness: .big, Array.init)
        let littleEndianBytes = value.withUnsafeBytes(endianness: .little, Array.init)

        XCTAssertEqual(bigEndianBytes, [0, 0, 0, 0, 0, 0, 0, 128])
        XCTAssertEqual(littleEndianBytes, [128, 0, 0, 0, 0, 0, 0, 0])

        XCTAssertEqual(bigEndianBytes.withUnsafeBytes({ UInt(buffer: $0, endianness: .big) }), 128)
        XCTAssertEqual(
            littleEndianBytes.withUnsafeBytes({
                UInt(buffer: $0, endianness: .little)
            }), 128)
    }

    func testSignedFixedWidthInteger() {
        let value: Int = -64

        let bigEndianBytes = value.withUnsafeBytes(endianness: .big, Array.init)
        let littleEndianBytes = value.withUnsafeBytes(endianness: .little, Array.init)

        XCTAssertEqual(bigEndianBytes, [255, 255, 255, 255, 255, 255, 255, 192])
        XCTAssertEqual(littleEndianBytes, [192, 255, 255, 255, 255, 255, 255, 255])

        XCTAssertEqual(bigEndianBytes.withUnsafeBytes({ Int(buffer: $0, endianness: .big) }), -64)
        XCTAssertEqual(
            littleEndianBytes.withUnsafeBytes({
                Int(buffer: $0, endianness: .little)
            }), -64)
    }

    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.5, *)
    func test16BitFloatingPoint() {
        let value: Float16 = -6.25

        let bigEndianBytes = value.withUnsafeBytes(endianness: .big, Array.init)
        let littleEndianBytes = value.withUnsafeBytes(endianness: .little, Array.init)

        XCTAssertEqual(bigEndianBytes, [198, 64])
        XCTAssertEqual(littleEndianBytes, [64, 198])

        XCTAssertEqual(
            bigEndianBytes.withUnsafeBytes({ Float16(buffer: $0, endianness: .big) }), -6.25)
        XCTAssertEqual(
            littleEndianBytes.withUnsafeBytes({
                Float16(buffer: $0, endianness: .little)
            }), -6.25)
    }

    func test32BitFloatingPoint() {
        let value: Float32 = -39.062_5

        let bigEndianBytes = value.withUnsafeBytes(endianness: .big, Array.init)
        let littleEndianBytes = value.withUnsafeBytes(endianness: .little, Array.init)

        XCTAssertEqual(bigEndianBytes, [194, 28, 64, 0])
        XCTAssertEqual(littleEndianBytes, [0, 64, 28, 194])

        XCTAssertEqual(
            bigEndianBytes.withUnsafeBytes({ Float32(buffer: $0, endianness: .big) }), -39.062_5)
        XCTAssertEqual(
            littleEndianBytes.withUnsafeBytes({
                Float32(buffer: $0, endianness: .little)
            }), -39.062_5)
    }

    func test64BitFloatingPoint() {
        let value: Float64 = -1_525.878_906_25

        let bigEndianBytes = value.withUnsafeBytes(endianness: .big, Array.init)
        let littleEndianBytes = value.withUnsafeBytes(endianness: .little, Array.init)

        XCTAssertEqual(bigEndianBytes, [192, 151, 215, 132, 0, 0, 0, 0])
        XCTAssertEqual(littleEndianBytes, [0, 0, 0, 0, 132, 215, 151, 192])

        XCTAssertEqual(
            bigEndianBytes.withUnsafeBytes({ Float64(buffer: $0, endianness: .big) }),
            -1_525.878_906_25)
        XCTAssertEqual(
            littleEndianBytes.withUnsafeBytes({
                Float64(buffer: $0, endianness: .little)
            }), -1_525.878_906_25)
    }

    func testHostEndianness() {
        let value: Float64 = -1_525.878_906_25

        let hostEndianBytes = value.withUnsafeBytes(Array.init)

        if Endianness.big == .host {
            XCTAssertEqual(hostEndianBytes, [192, 151, 215, 132, 0, 0, 0, 0])
        } else if Endianness.little == .host {
            XCTAssertEqual(hostEndianBytes, [0, 0, 0, 0, 132, 215, 151, 192])
        } else {
            XCTFail()
        }

        XCTAssertEqual(hostEndianBytes.withUnsafeBytes({ Float64(buffer: $0) }), -1_525.878_906_25)
    }
}
