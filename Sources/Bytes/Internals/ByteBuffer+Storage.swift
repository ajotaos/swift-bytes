#if os(Windows)
    import ucrt
#elseif os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#else
    import Glibc
#endif

extension ByteBuffer {
    final class Storage {
        private var baseAddress: UnsafeMutableRawPointer
        private(set) var capacity: Int

        private init(baseAddress: UnsafeMutableRawPointer, capacity: Int) {
            self.baseAddress = baseAddress
            self.capacity = capacity

            bindMemory()
        }

        private func bindMemory() {
            baseAddress.bindMemory(to: UInt8.self, capacity: capacity)
        }

        deinit {
            deallocate()
        }
    }
}

extension ByteBuffer.Storage {
    static func allocate(_ capacity: Int = 0) -> ByteBuffer.Storage {
        precondition(capacity >= 0)

        if let baseAddress = malloc(capacity) {
            return .init(baseAddress: baseAddress, capacity: capacity)
        } else {
            fatalError("Insufficient memory to allocate requested capacity")
        }
    }

    func reallocate(to minimumCapacity: Int, shouldAttemptToGrowCapacity: Bool = false) {
        precondition(minimumCapacity >= 0)

        let capacity =
            shouldAttemptToGrowCapacity
            ? calculateGrownCapacity(for: minimumCapacity) : minimumCapacity

        if let baseAddress = realloc(baseAddress, capacity) {
            self.baseAddress = baseAddress
            self.capacity = capacity

            bindMemory()
        } else if minimumCapacity < capacity,
            let baseAddress = realloc(baseAddress, minimumCapacity)
        {
            self.baseAddress = baseAddress
            self.capacity = minimumCapacity

            bindMemory()
        } else {
            fatalError("Insufficient memory to allocate requested capacity")
        }
    }

    func reallocateIfNeeded(to minimumCapacity: Int, shouldAttemptToGrowCapacity: Bool = false) {
        if minimumCapacity > capacity {
            reallocate(
                to: minimumCapacity, shouldAttemptToGrowCapacity: shouldAttemptToGrowCapacity)
        }
    }

    private func deallocate() {
        free(baseAddress)
    }
}

extension ByteBuffer.Storage {
    func withUnsafeBytes<T>(_ body: (_ buffer: UnsafeRawBufferPointer) throws -> T) rethrows -> T {
        try body(.init(start: baseAddress, count: capacity))
    }

    func withUnsafeMutableBytes<T>(_ body: (_ buffer: UnsafeMutableRawBufferPointer) throws -> T)
        rethrows
        -> T
    {
        try body(.init(start: baseAddress, count: capacity))
    }
}

extension ByteBuffer.Storage {
    func copyBytes(
        from source: some Sequence<UInt8>, toByteOffset offset: Int = 0,
        shouldAttemptToGrowCapacity: Bool = false
    ) -> Int {
        precondition(offset >= 0, "Negative byte offset is out of bounds")

        if let count = source.withContiguousStorageIfAvailable({
            copyMemory(
                from: .init($0), toByteOffset: offset,
                shouldAttemptToGrowCapacity: shouldAttemptToGrowCapacity)
        }) {
            return count
        } else {
            reallocateIfNeeded(
                to: offset + source.underestimatedCount,
                shouldAttemptToGrowCapacity: shouldAttemptToGrowCapacity)

            var (unwritten, initialized) = UnsafeMutableRawBufferPointer(
                start: baseAddress + offset, count: source.underestimatedCount
            ).initializeMemory(as: UInt8.self, from: source)
            assert(initialized.count == source.underestimatedCount)

            var count = initialized.count

            while var byte = unwritten.next() {
                count += Swift.withUnsafeBytes(of: &byte) {
                    copyMemory(
                        from: $0, toByteOffset: offset + count,
                        shouldAttemptToGrowCapacity: shouldAttemptToGrowCapacity)
                }
            }

            return count
        }
    }

    func copyMemory(
        from source: UnsafeRawBufferPointer, toByteOffset offset: Int = 0,
        shouldAttemptToGrowCapacity: Bool = false
    ) -> Int {
        precondition(offset >= 0, "Byte offset is out of bounds")

        let minimumCapacity = offset + source.count

        reallocateIfNeeded(
            to: minimumCapacity, shouldAttemptToGrowCapacity: shouldAttemptToGrowCapacity)

        UnsafeMutableRawBufferPointer(start: baseAddress + offset, count: source.count).copyMemory(
            from: source)

        return source.count
    }
}
