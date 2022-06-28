extension ByteBuffer {
    public init(string: String) {
        self.init(bytes: string.utf8)
    }

    public func readString(fromByteOffset offset: Int = 0, byteCount count: Int) -> String {
        precondition(offset >= 0, "Negative byte offset is out of bounds")
        precondition(count >= 0, "Byte count can't be less than zero")
        precondition(offset + count <= self.count, "Byte range is out of bounds")

        return withUnsafeBytes({ buffer in
            .init(
                unsafeUninitializedCapacity: count,
                initializingUTF8With: { $0.initialize(from: buffer[offset ..< offset + count]).1 })
        })
    }

    public mutating func writeString(_ string: String, toByteOffset offset: Int = 0) -> Int {
        writeBytes(string.utf8, toByteOffset: offset)
    }
}
