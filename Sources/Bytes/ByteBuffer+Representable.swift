extension ByteBuffer {
    public init(value: some BufferRepresentable, endianness: Endianness = .host) {
        self.init(
            unsafeUninitializedCapacity: type(of: value).byteSize,
            initializingWith: { mutableBuffer in
                value.withUnsafeBytes(
                    endianness: endianness,
                    {
                        mutableBuffer.copyMemory(from: $0)

                        return $0.count
                    })
            })
    }

    public func readRepresentableValue<R: BufferRepresentable>(
        fromByteOffset offset: Int = 0, endianness: Endianness = .host, as: R.Type
    ) -> R {
        precondition(offset >= 0, "Negative byte offset is out of bounds")
        precondition(R.byteSize >= 0, "Byte count can't be less than zero")
        precondition(offset + R.byteSize <= count, "Byte range is out of bounds")

        return withUnsafeBytes({
            .init(
                buffer: .init(rebasing: $0[offset..<offset + R.byteSize]),
                endianness: endianness)
        })
    }

    public mutating func writeRepresentableValue(
        _ value: some BufferRepresentable, toByteOffset offset: Int = 0,
        endianness: Endianness = .host
    ) -> Int {
        value.withUnsafeBytes(
            endianness: endianness,
            { copyMemory(from: $0, toByteOffset: offset, shouldAttemptToGrowCapacity: true) })
    }
}

extension ByteBuffer {
    public init(values: [some BufferRepresentable], endianness: Endianness = .host) {
        self.init(
            unsafeUninitializedCapacity: type(of: values).Element.byteSize * values.count,
            initializingWith: { mutableBuffer in
                var offset = 0

                for value in values {
                    offset += value.withUnsafeBytes(
                        endianness: endianness,
                        {
                            UnsafeMutableRawBufferPointer(
                                rebasing: mutableBuffer[
                                    offset..<offset + type(of: values).Element.byteSize]
                            ).copyMemory(from: $0)

                            return $0.count
                        })
                }

                return offset
            })
    }

    public func readRepresentableValues<R: BufferRepresentable>(
        fromByteOffset offset: Int = 0, count: Int, endianness: Endianness = .host, as: R.Type
    ) -> some RandomAccessCollection<R> {
        var values: [R] = []

        values.reserveCapacity(count)

        for offset in stride(from: 0, to: R.byteSize * count, by: R.byteSize) {
            values.append(
                withUnsafeBytes({
                    .init(
                        buffer: .init(rebasing: $0[offset..<offset + R.byteSize]),
                        endianness: endianness)
                }))
        }

        return values
    }

    public mutating func writeRepresentableValues(
        _ values: [some BufferRepresentable], toByteOffset offset: Int = 0,
        endianness: Endianness = .host
    ) -> Int {
        reserveCapacity(offset + type(of: values).Element.byteSize * values.count)
        
        var count = 0

        for value in values {
            count += value.withUnsafeBytes(
                endianness: endianness,
                {
                    copyMemory(from: $0, toByteOffset: offset + count)
                })
        }

        return count
    }
}
