import XCTest

@testable import Bytes

final class ByteBufferTests_Storage: XCTestCase {
    func testAllocateWithCapacity() {
        let storage = ByteBuffer.Storage.allocate(4)

        XCTAssertEqual(storage.capacity, 4)
    }

    func testReallocateToMinimumCapacity() {
        let storage = ByteBuffer.Storage.allocate(4)

        storage.reallocate(to: 8)

        XCTAssertEqual(storage.capacity, 8)
    }

    func testReallocateToMinimumCapacityAndAttemptToGrow() {
        let storage = ByteBuffer.Storage.allocate(4)

        storage.reallocate(to: 8, shouldAttemptToGrowCapacity: true)

        XCTAssertEqual(storage.capacity, 12)
    }

    func testAttemptToReallocateToLesserCapacity() {
        let storage = ByteBuffer.Storage.allocate(4)

        storage.reallocate(to: 2)

        XCTAssertEqual(storage.capacity, 2)
    }

    func testAttemptToReallocateIfNeededToLesserCapacity() {
        let storage = ByteBuffer.Storage.allocate(4)

        storage.reallocateIfNeeded(to: 2)

        XCTAssertEqual(storage.capacity, 4)
    }

    func testCopyBytesFromContiguousSequence() {
        let storage = ByteBuffer.Storage.allocate(8)

        XCTAssertEqual(storage.copyBytes(from: [0, 1, 2, 3], toByteOffset: 0), 4)
        XCTAssertEqual(storage.copyBytes(from: [3, 2, 1, 0], toByteOffset: 4), 4)

        XCTAssertEqual(storage.withUnsafeBytes(Array.init), [0, 1, 2, 3, 3, 2, 1, 0])
    }

    func testCopyBytesFromDiscontiguousSequenceWithAccurateUnderestimatedCount() {
        let storage = ByteBuffer.Storage.allocate(8)

        XCTAssertEqual(
            storage.copyBytes(from: stride(from: 0, through: 3, by: 1), toByteOffset: 0), 4)
        XCTAssertEqual(
            storage.copyBytes(from: stride(from: 3, through: 0, by: -1), toByteOffset: 4), 4)

        XCTAssertEqual(storage.withUnsafeBytes(Array.init), [0, 1, 2, 3, 3, 2, 1, 0])
    }

    func testCopyBytesFromDiscontiguousSequenceWithInaccurateUnderestimatedCount() {
        let storage = ByteBuffer.Storage.allocate(8)

        XCTAssertEqual(
            storage.copyBytes(
                from: InaccurateUnderstimatedCountSequence(stride(from: 0, through: 3, by: 1)),
                toByteOffset: 0), 4)
        XCTAssertEqual(
            storage.copyBytes(
                from: InaccurateUnderstimatedCountSequence(stride(from: 3, through: 0, by: -1)),
                toByteOffset: 4), 4)

        XCTAssertEqual(storage.withUnsafeBytes(Array.init), [0, 1, 2, 3, 3, 2, 1, 0])
    }

    func testCopyMemory() {
        let mutableBuffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 4, alignment: 1)

        let storage = ByteBuffer.Storage.allocate(8)

        mutableBuffer.copyBytes(from: [0, 1, 2, 3])

        XCTAssertEqual(storage.copyMemory(from: .init(mutableBuffer), toByteOffset: 0), 4)

        mutableBuffer.copyBytes(from: [3, 2, 1, 0])

        XCTAssertEqual(storage.copyMemory(from: .init(mutableBuffer), toByteOffset: 4), 4)

        XCTAssertEqual(storage.withUnsafeBytes(Array.init), [0, 1, 2, 3, 3, 2, 1, 0])
    }

    func testWithUnsafeBytes() {
        let storage = ByteBuffer.Storage.allocate(8)

        XCTAssertEqual(storage.copyBytes(from: [0, 1, 2, 3, 3, 2, 1, 0], toByteOffset: 0), 8)

        XCTAssertEqual(storage.withUnsafeBytes(Array.init), [0, 1, 2, 3, 3, 2, 1, 0])
    }

    func testWithUnsafeMutableBytes() {
        let storage = ByteBuffer.Storage.allocate(8)

        XCTAssertEqual(
            storage.withUnsafeMutableBytes({
                $0.initializeMemory(as: UInt8.self, from: [3, 2, 1, 0, 0, 1, 2, 3]).initialized
                    .count
            }), 8)

        XCTAssertEqual(storage.withUnsafeBytes(Array.init), [3, 2, 1, 0, 0, 1, 2, 3])
    }
}

private struct InaccurateUnderstimatedCountSequence<S: Sequence>: Sequence {
    private var values: S

    fileprivate init(_ values: S) {
        self.values = values
    }

    fileprivate func makeIterator() -> S.Iterator { values.makeIterator() }
}
