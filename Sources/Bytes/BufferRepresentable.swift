public protocol BufferRepresentable {
    init(buffer: UnsafeRawBufferPointer, endianness: Endianness)

    func withUnsafeBytes<T>(
        endianness: Endianness, _ body: (_ buffer: UnsafeRawBufferPointer) throws -> T
    ) rethrows -> T
}

extension BufferRepresentable {
    public static var byteSize: Int { MemoryLayout<Self>.size }
}

extension BufferRepresentable where Self: FixedWidthInteger {
    public init(buffer: UnsafeRawBufferPointer, endianness: Endianness = .host) {
        let value = buffer.load(as: Self.self)

        self = endianness != .host ? value.byteSwapped : value
    }

    public func withUnsafeBytes<T>(
        endianness: Endianness = .host, _ body: (_ buffer: UnsafeRawBufferPointer) throws -> T
    ) rethrows -> T {
        let value = endianness != .host ? byteSwapped : self

        return try Swift.withUnsafeBytes(of: value, body)
    }
}

extension UInt8: BufferRepresentable {}
extension UInt16: BufferRepresentable {}
extension UInt32: BufferRepresentable {}
extension UInt64: BufferRepresentable {}
extension UInt: BufferRepresentable {}

extension Int8: BufferRepresentable {}
extension Int16: BufferRepresentable {}
extension Int32: BufferRepresentable {}
extension Int64: BufferRepresentable {}
extension Int: BufferRepresentable {}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.5, *)
extension Float16: BufferRepresentable {
    public init(buffer: UnsafeRawBufferPointer, endianness: Endianness = .host) {
        self.init(bitPattern: .init(buffer: buffer, endianness: endianness))
    }

    public func withUnsafeBytes<T>(
        endianness: Endianness = .host, _ body: (UnsafeRawBufferPointer) throws -> T
    ) rethrows -> T {
        try bitPattern.withUnsafeBytes(endianness: endianness, body)
    }
}

extension Float32: BufferRepresentable {
    public init(buffer: UnsafeRawBufferPointer, endianness: Endianness = .host) {
        self.init(bitPattern: .init(buffer: buffer, endianness: endianness))
    }

    public func withUnsafeBytes<T>(
        endianness: Endianness = .host, _ body: (UnsafeRawBufferPointer) throws -> T
    ) rethrows -> T {
        try bitPattern.withUnsafeBytes(endianness: endianness, body)
    }
}

extension Float64: BufferRepresentable {
    public init(buffer: UnsafeRawBufferPointer, endianness: Endianness = .host) {
        self.init(bitPattern: .init(buffer: buffer, endianness: endianness))
    }

    public func withUnsafeBytes<T>(
        endianness: Endianness = .host, _ body: (UnsafeRawBufferPointer) throws -> T
    ) rethrows -> T {
        try bitPattern.withUnsafeBytes(endianness: endianness, body)
    }
}
