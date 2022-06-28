public typealias Byte = UInt8

public struct ByteBuffer {
    public var count: Int { bounds.count }
    public var capacity: Int { storage.capacity }

    private var storage: Storage
    private var bounds: Range<Int> = 0..<0

    public init() {
        self.storage = .allocate()
    }

    public init(bytes source: some Sequence<Byte>) {
        self.storage = .allocate()

        let count = storage.copyBytes(from: source)

        self.bounds = 0..<count
    }

    public init(bytes source: UnsafeRawBufferPointer) {
        self.storage = .allocate()

        let count = storage.copyMemory(from: source)

        self.bounds = 0..<count
    }

    public init(
        unsafeUninitializedCapacity capacity: Int,
        initializingWith initializer: (_ buffer: UnsafeMutableRawBufferPointer) throws -> Int
    ) rethrows {
        precondition(capacity >= 0, "Buffer capacity can't be less than zero")

        self.storage = .allocate(capacity)

        let count = try storage.withUnsafeMutableBytes(initializer)

        self.bounds = 0..<count
    }

    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        precondition(minimumCapacity >= 0, "Buffer capacity can't be less than zero")

        storage.reallocateIfNeeded(to: minimumCapacity, shouldAttemptToGrowCapacity: true)
    }
}

extension ByteBuffer {
    public subscript(bounds: Range<Int>) -> ByteBuffer {
        precondition(bounds.lowerBound >= 0, "Negative byte offset is out of bounds")
        precondition(bounds.upperBound <= count, "Byte range is out of bounds")

        var slice = self
        slice.bounds = bounds

        return slice
    }
}

extension ByteBuffer {
    public func readBytes(fromByteOffset offset: Int = 0, byteCount count: Int)
        -> some RandomAccessCollection<Byte>
    {
        precondition(offset >= 0, "Negative byte offset is out of bounds")
        precondition(count >= 0, "Byte count can't be less than zero")
        precondition(offset + count <= self.count, "Byte range is out of bounds")

        return withUnsafeBytes({ Array($0[offset..<offset + count]) })
    }

    public mutating func writeBytes(_ source: some Sequence<Byte>, toByteOffset offset: Int = 0)
        -> Int
    {
        copyBytes(from: source, toByteOffset: offset, shouldAttemptToGrowCapacity: true)
    }

    public mutating func writeBytes(_ source: UnsafeRawBufferPointer, toByteOffset offset: Int = 0)
        -> Int
    {
        copyMemory(from: source, toByteOffset: offset, shouldAttemptToGrowCapacity: true)
    }
}

extension ByteBuffer {
    public func withUnsafeBytes<T>(_ body: (_ buffer: UnsafeRawBufferPointer) throws -> T) rethrows
        -> T
    {
        try storage.withUnsafeBytes({ try body(.init(rebasing: $0[bounds])) })
    }

    public mutating func withUnsafeMutableBytes<T>(
        _ body: (_ buffer: UnsafeMutableRawBufferPointer) throws -> T
    ) rethrows -> T {
        copyStorageIfNeeded()

        return try storage.withUnsafeMutableBytes({ try body(.init(rebasing: $0[bounds])) })
    }
}

extension ByteBuffer {
    mutating func copyBytes(
        from source: some Sequence<Byte>, toByteOffset offset: Int = 0,
        shouldAttemptToGrowCapacity: Bool = false
    ) -> Int {
        precondition(offset >= 0, "Negative byte offset is out of bounds")

        copyStorageIfNeeded()

        let count = storage.copyBytes(
            from: source, toByteOffset: bounds.lowerBound + offset,
            shouldAttemptToGrowCapacity: shouldAttemptToGrowCapacity)

        updateBoundsIfNeeded(offset: offset, count: count)

        return count
    }

    mutating func copyMemory(
        from source: UnsafeRawBufferPointer, toByteOffset offset: Int = 0,
        shouldAttemptToGrowCapacity: Bool = false
    ) -> Int {
        precondition(offset >= 0, "Negative byte offset is out of bounds")

        copyStorageIfNeeded()

        let count = storage.copyMemory(
            from: source, toByteOffset: bounds.lowerBound + offset,
            shouldAttemptToGrowCapacity: shouldAttemptToGrowCapacity)

        updateBoundsIfNeeded(offset: offset, count: count)

        return count
    }

    private mutating func copyStorageIfNeeded() {
        guard !isKnownUniquelyReferenced(&storage) else { return }

        let storage: Storage = .allocate(count)
        let count = withUnsafeBytes({ storage.copyMemory(from: $0) })

        self.storage = storage
        bounds = 0..<count
    }

    private mutating func updateBoundsIfNeeded(offset: Int, count: Int) {
        let lowerBound = bounds.lowerBound
        let upperBound = max(lowerBound + offset + count, bounds.upperBound)

        bounds = lowerBound..<upperBound
    }
}

extension ByteBuffer: Equatable {
    public static func == (lhs: ByteBuffer, rhs: ByteBuffer) -> Bool {
        guard lhs.count == rhs.count else { return false }

        return lhs.withUnsafeBytes({ lhsBuffer in
            rhs.withUnsafeBytes({ rhsBuffer in lhsBuffer.elementsEqual(rhsBuffer) })
        })
    }
}

extension ByteBuffer: Hashable {
    public func hash(into hasher: inout Hasher) {
        withUnsafeBytes({ hasher.combine(bytes: $0) })
    }
}

extension ByteBuffer: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(withUnsafeBytes(Array.init))
    }
}

extension ByteBuffer: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let bytes = try container.decode([Byte].self)

        self.init(bytes: bytes)
    }
}
