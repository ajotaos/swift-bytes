//
//  BytesTests.swift
//
//
//  Created by Álvaro Ortiz on 5/10/23.
//

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
    
    func testInitializeWithUnsafeUninitializedCapacityAndInitializer() {
        let bytes: [UInt8] = [0, 1, 2, 3]
        let buffer = ByteBuffer(
            unsafeUninitializedCapacity: bytes.capacity,
            initializingWith: {
                $0.copyBytes(from: bytes)
                
                return $0.count
            }
        )
        
        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 4)
        
        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [0, 1, 2, 3])
    }
    
    func testReserveCapacity() {
        var buffer = ByteBuffer()
        
        buffer.reserveCapacity(8)
        
        XCTAssertEqual(buffer.count, 0)
        XCTAssertEqual(buffer.capacity, 12)
    }
    
    func testWriteBytes() {
        var buffer = ByteBuffer()
        
        XCTAssertEqual(buffer.write(bytes: [0, 1, 2, 3]), 4)
        
        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 6)
        
        XCTAssertEqual(buffer.write(bytes: [3, 2, 1, 0], at: 4), 4)
        
        XCTAssertEqual(buffer.count, 8)
        XCTAssertEqual(buffer.capacity, 12)
        
        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [0, 1, 2, 3, 3, 2, 1, 0])
    }
    
    func testReadBytes() {
        let buffer = ByteBuffer(bytes: [0, 1, 2, 3, 3, 2, 1, 0])
        
        XCTAssertEqual(buffer.bytes(count: 4), [0, 1, 2, 3])
        XCTAssertEqual(buffer.bytes(at: 4, count: 4), [3, 2, 1, 0])
    }
    
    func testInitializeWithInteger() {
        let buffer = ByteBuffer(integer: UInt32(0x0001_0203), endianness: .big)
        
        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 4)
        
        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [0, 1, 2, 3])
    }
    
    func testWriteInteger() {
        var buffer = ByteBuffer()
        
        XCTAssertEqual(buffer.write(integer: UInt32(0x0001_0203), endianness: .big), 4)
        
        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 6)
        
        XCTAssertEqual(buffer.write(integer: UInt32(0x0001_0203), at: 4, endianness: .little), 4)
        
        XCTAssertEqual(buffer.count, 8)
        XCTAssertEqual(buffer.capacity, 12)
        
        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [0, 1, 2, 3, 3, 2, 1, 0])
    }
    
    func testReadInteger() {
        let buffer = ByteBuffer(integer: UInt64(0x0001_0203_0001_0203), endianness: .big)
        
        XCTAssertEqual(buffer.integer(endianness: .big, as: UInt32.self), 0x0001_0203)
        XCTAssertEqual(buffer.integer(at: 4, endianness: .little, as: UInt32.self), 0x0302_0100)
    }
    
    func testInitializeWithFloatingPoint() {
        let buffer = ByteBuffer(floatingPoint: Float32(bitPattern: 0x0001_0203), endianness: .big)
        
        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 4)
        
        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [0, 1, 2, 3])
    }
    
    func testWriteFloatingPoint() {
        var buffer = ByteBuffer()
        
        XCTAssertEqual(
            buffer.write(floatingPoint: Float32(bitPattern: 0x0001_0203), endianness: .big),
            4
        )
        
        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 6)
        
        XCTAssertEqual(
            buffer.write(
                floatingPoint: Float32(bitPattern: 0x0001_0203),
                at: 4,
                endianness: .little
            ),
            4
        )
        
        XCTAssertEqual(buffer.count, 8)
        XCTAssertEqual(buffer.capacity, 12)
        
        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [0, 1, 2, 3, 3, 2, 1, 0])
    }
    
    func testReadFloatingPoint() {
        let buffer = ByteBuffer(
            floatingPoint: Float64(bitPattern: 0x0001_0203_0001_0203),
            endianness: .big
        )
        
        XCTAssertEqual(
            buffer.floatingPoint(endianness: .big, as: Float32.self),
            Float32(bitPattern: 0x0001_0203)
        )
        XCTAssertEqual(
            buffer.floatingPoint(at: 4, endianness: .little, as: Float32.self),
            Float32(bitPattern: 0x0302_0100)
        )
    }
    
    func testInitializeWithString() {
        let buffer = ByteBuffer(string: "abcd")
        
        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 4)
        
        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [97, 98, 99, 100])
    }
    
    func testWriteString() {
        var buffer = ByteBuffer()
        
        XCTAssertEqual(buffer.write(string: "abcd"), 4)
        
        XCTAssertEqual(buffer.count, 4)
        XCTAssertEqual(buffer.capacity, 6)
        
        XCTAssertEqual(buffer.write(string: "dcba", at: 4), 4)
        
        XCTAssertEqual(buffer.count, 8)
        XCTAssertEqual(buffer.capacity, 12)
        
        XCTAssertEqual(buffer.withUnsafeBytes(Array.init), [97, 98, 99, 100, 100, 99, 98, 97])
    }
    
    func testReadString() {
        let buffer = ByteBuffer(string: "abcddcba")
        
        XCTAssertEqual(buffer.string(count: 4), "abcd")
        XCTAssertEqual(buffer.string(at: 4, count: 4), "dcba")
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
            decoder.decode(ByteBuffer.self, from: data),
            ByteBuffer(bytes: [0, 1, 2, 3])
        )
    }
    
    func testExpressibleByArrayLiteralConformance() {
        let buffer: ByteBuffer = [0, 1, 2, 3]
        
        XCTAssertEqual(buffer,ByteBuffer(bytes: [0, 1, 2, 3]))
    }
}
