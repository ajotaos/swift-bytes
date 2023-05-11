//
//  ByteBuffer.swift
//
//
//  Created by Álvaro Ortiz on 5/10/23.
//

public struct ByteBuffer {
    public var count: Int {
        self.bounds.count
    }
    
    public var capacity: Int {
        self.storage.capacity
    }
    
    private var storage: ByteBufferStorage
    private var bounds: Range<Int> = 0..<0
    
    private var region: ByteBufferStorage.Region {
        self.storage.region(in: self.bounds)
    }
    
    public init() {
        self.storage = .allocate()
    }
    
    public init(bytes: some Sequence<UInt8>) {
        self.init()
        
        self._write(bytes: bytes)
    }
    
    public init(
        unsafeUninitializedCapacity capacity: Int,
        initializingWith initializer: (_ mutableBytes: UnsafeMutableRawBufferPointer) throws -> Int
    ) rethrows {
        precondition(capacity >= 0, "Buffer capacity cannot be less than zero")
        
        self.storage = .allocate(capacity: capacity)
        
        let uninitializedRegion = self.storage.region(in: 0..<capacity)
        let count = try initializer(uninitializedRegion.asUnsafeMutableBytes())
        precondition(
            count <= capacity,
            "Initialized count cannot be greater than specified buffer capacity"
        )
        self.expandBoundsIfNeeded(count: count)
    }
    
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        precondition(minimumCapacity >= 0, "Buffer capacity cannot be less than zero")
        
        self.copyStorageIfNeeded()
        self.storage.growCapacityIfNeeded(minimumCapacity, shouldApplyGrowthStrategy: true)
    }
}

extension ByteBuffer {
    @discardableResult
    public mutating func write(bytes: some Sequence<UInt8>, at offset: Int = 0) -> Int {
        self._write(bytes: bytes, at: offset, options: [.applyGrowthStrategy])
    }
    
    public func bytes(at offset: Int = 0, count: Int) -> [UInt8] {
        self._withUnsafeBytes(offset: offset, count: count, Array.init)
    }
}

extension ByteBuffer {
    public init<I: FixedWidthInteger>(integer: I, endianness: Endianness = .host) {
        let capacity = MemoryLayout<I>.size
        self.storage = .allocate(capacity: capacity)
        
        self._write(integer: integer, endianness: endianness)
    }
    
    @discardableResult
    public mutating func write<I: FixedWidthInteger>(
        integer: I,
        at offset: Int = 0,
        endianness: Endianness = .host
    ) -> Int {
        self._write(
            integer: integer,
            at: offset,
            endianness: endianness,
            options: [.applyGrowthStrategy]
        )
    }
    
    public func integer<I: FixedWidthInteger>(
        at offset: Int = 0,
        endianness: Endianness = .host,
        as _: I.Type
    ) -> I {
        let count = MemoryLayout<I>.size
        let integer = self._withUnsafeBytes(offset: offset, count: count, {
            $0.load(as: I.self)
        })
        
        return endianness == .host ? integer : integer.byteSwapped
    }
}

extension ByteBuffer {
    public init<F: BinaryFloatingPoint>(floatingPoint: F, endianness: Endianness = .host)
    where F.RawSignificand: FixedWidthInteger {
        let capacity = MemoryLayout<F.RawSignificand>.size
        self.storage = .allocate(capacity: capacity)
        
        self._write(floatingPoint: floatingPoint, endianness: endianness)
    }
    
    @discardableResult
    public mutating func write<F: BinaryFloatingPoint>(
        floatingPoint: F,
        at offset: Int = 0,
        endianness: Endianness = .host
    ) -> Int where F.RawSignificand: FixedWidthInteger {
        self._write(
            floatingPoint: floatingPoint,
            at: offset,
            endianness: endianness,
            options: [.applyGrowthStrategy]
        )
    }
    
    public func floatingPoint<F: BinaryFloatingPoint>(
        at offset: Int = 0,
        endianness: Endianness = .host,
        as _: F.Type
    ) -> F where F.RawSignificand: FixedWidthInteger {
        let count = MemoryLayout<F.RawSignificand>.size
        let bitPattern = self._withUnsafeBytes(offset: offset, count: count, {
            $0.load(as: F.RawSignificand.self)
        })
        
        return getFloatingPoint(
            bitPattern: endianness == .host ? bitPattern : bitPattern.byteSwapped
        )
    }
}

extension ByteBuffer {
    public init(string: String) {
        self.init(bytes: string.utf8)
    }
    
    @discardableResult
    public mutating func write(string: String, at offset: Int = 0) -> Int {
        self._write(string: string, at: offset, options: [.applyGrowthStrategy])
    }
    
    public func string(at offset: Int = 0, count: Int) -> String {
        self._withUnsafeBytes(offset: offset, count: count, {
            String(decoding: $0, as: UTF8.self)
        })
    }
}

extension ByteBuffer {
    public func withUnsafeBytes<T>(
        _ body: (_ bytes: UnsafeRawBufferPointer) throws -> T
    ) rethrows -> T {
        return try body(self.region.asUnsafeBytes())
    }
    
    public mutating func withUnsafeMutableBytes<T>(
        _ body: (_ mutableBytes: UnsafeMutableRawBufferPointer) throws -> T
    ) rethrows -> T {
        self.copyStorageIfNeeded()
        
        return try body(self.region.asUnsafeMutableBytes())
    }
}

extension ByteBuffer {
    private func _withUnsafeBytes<T>(
        offset: Int = 0,
        count: Int,
        _ body: (_ bytes: UnsafeRawBufferPointer) throws -> T
    ) rethrows -> T {
        precondition(offset >= 0, "Byte offset cannot be less than zero")
        precondition(count >= 0, "Byte count cannot be less than zero")
        precondition(offset + count <= self.bounds.count, "Range exceeds buffer contents")
        
        let range = self.bounds.lowerBound + offset..<self.bounds.lowerBound + offset + count
        let region = self.storage.region(in: range)
        
        return try body(region.asUnsafeBytes())
    }
    
    @discardableResult
    private mutating func _write(
        bytes: some Sequence<UInt8>,
        at offset: Int = 0,
        options: ByteBufferStorage.CopyOptions = []
    ) -> Int {
        precondition(offset >= 0, "Byte offset cannot be less than zero")
        
        self.copyStorageIfNeeded()
        
        let count = self.storage.copyBytes(
            from: bytes,
            at: self.bounds.lowerBound + offset,
            options: options
        )
        self.expandBoundsIfNeeded(offset: offset, count: count)
        
        return count
    }
    
    @discardableResult
    private mutating func _write<I: FixedWidthInteger>(
        integer: I,
        at offset: Int = 0,
        endianness: Endianness = .host,
        options: ByteBufferStorage.CopyOptions = []
    ) -> Int {
        var integer = endianness == .host ? integer : integer.byteSwapped
        let count = Swift.withUnsafeBytes(of: &integer, {
            self._write(bytes: $0, at: offset, options: options)
        })
        
        return count
    }
    
    @discardableResult
    private mutating func _write<F: BinaryFloatingPoint>(
        floatingPoint: F,
        at offset: Int = 0,
        endianness: Endianness = .host,
        options: ByteBufferStorage.CopyOptions = []
    ) -> Int where F.RawSignificand: FixedWidthInteger {
        var bitPattern = getFloatingPointBitPattern(floatingPoint)
        bitPattern = endianness == .host ? bitPattern : bitPattern.byteSwapped
        let count = Swift.withUnsafeBytes(of: &bitPattern, {
            self._write(bytes: $0, at: offset, options: options)
        })
        
        return count
    }
    
    @discardableResult
    private mutating func _write(
        string: String,
        at offset: Int = 0,
        options: ByteBufferStorage.CopyOptions = []
    ) -> Int {
        self._write(bytes: string.utf8, at: offset, options: options)
    }
}

extension ByteBuffer {
    private mutating func copyStorageIfNeeded() {
        guard !isKnownUniquelyReferenced(&self.storage) else {
            return
        }
        
        let storage = ByteBufferStorage.allocate(capacity: self.bounds.count)
        let count = self.withUnsafeBytes({ storage.copyMemory(from: $0) })
        
        self.storage = storage
        self.bounds = 0..<count
    }
    
    private mutating func expandBoundsIfNeeded(offset: Int = 0, count: Int) {
        let lowerBound = self.bounds.lowerBound
        let upperBound = max(lowerBound + offset + count, self.bounds.upperBound)
        
        self.bounds = lowerBound..<upperBound
    }
}

extension ByteBuffer: Equatable {
    public static func == (lhs: ByteBuffer, rhs: ByteBuffer) -> Bool {
        if lhs.storage === rhs.storage, lhs.bounds == rhs.bounds {
            return true
        }
        
        return lhs.region.compareBytes(to: rhs.region)
    }
}

extension ByteBuffer: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.withUnsafeBytes({ hasher.combine(bytes: $0) })
    }
}

extension ByteBuffer: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        let bytes = self.withUnsafeBytes(Array.init)
        try container.encode(bytes)
    }
}

extension ByteBuffer: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let bytes = try container.decode([UInt8].self)
        
        self.init(bytes: bytes)
    }
}

extension ByteBuffer: ExpressibleByArrayLiteral {
    public init(arrayLiteral bytes: UInt8...) {
        self.init(bytes: bytes)
    }
}

private func getFloatingPointBitPattern<F: BinaryFloatingPoint>(_ floatingPoint: F) -> F.RawSignificand {
    var bitPattern: F.RawSignificand = 0
    bitPattern |=
    F.RawSignificand(floatingPoint.sign.rawValue)
    << (F.exponentBitCount + F.significandBitCount)
    bitPattern |= F.RawSignificand(floatingPoint.exponentBitPattern) << F.significandBitCount
    bitPattern |= floatingPoint.significandBitPattern
    
    return bitPattern
}

private func getFloatingPoint<F: BinaryFloatingPoint>(bitPattern: F.RawSignificand) -> F {
    let sign: FloatingPointSign =
    bitPattern >> (F.exponentBitCount + F.significandBitCount) == 0 ? .plus : .minus
    let exponentBitPattern = F.RawExponent(
        (bitPattern & ((1 << F.exponentBitCount - 1) << F.significandBitCount))
        >> F.significandBitCount
    )
    let significandBitPattern = bitPattern & (1 << F.significandBitCount - 1)
    
    return F(
        sign: sign,
        exponentBitPattern: exponentBitPattern,
        significandBitPattern: significandBitPattern
    )
}
