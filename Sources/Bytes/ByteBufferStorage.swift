//
//  ByteBufferStorage.swift
//
//
//  Created by Álvaro Ortiz on 5/10/23.
//

#if os(Windows)
import ucrt
#elseif os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Darwin
#else
import Glibc
#endif

internal final class ByteBufferStorage {
    internal private(set) var baseAddress: UnsafeMutableRawPointer
    internal private(set) var capacity: Int
    
    internal init(baseAddress: UnsafeMutableRawPointer, capacity: Int) {
        self.baseAddress = baseAddress
        self.capacity = capacity
        
        self.bindMemory()
    }
    
    internal static func allocate(capacity: Int = 0) -> ByteBufferStorage {
        precondition(capacity >= 0, "Buffer capacity cannot be less than zero")
        
        guard let baseAddress = malloc(capacity) else {
            fatalError("Memory was insufficient to allocate requested capacity")
        }
        
        return ByteBufferStorage(baseAddress: baseAddress, capacity: capacity)
    }
    
    internal func reallocate(toCapacity newCapacity: Int) {
        precondition(newCapacity >= 0, "Buffer capacity cannot be less than zero")
        
        guard let newBaseAddress = realloc(self.baseAddress, newCapacity) else {
            fatalError("Memory was insufficient to allocate requested capacity")
        }
        
        self.baseAddress = newBaseAddress
        self.capacity = newCapacity
        
        self.bindMemory()
    }
    
    private func bindMemory() {
        self.baseAddress.bindMemory(to: UInt8.self, capacity: self.capacity)
    }
    
    private func deallocate() {
        free(self.baseAddress)
    }
    
    deinit {
        self.deallocate()
    }
}

extension ByteBufferStorage {
    internal struct Region {
        internal let baseAddress: UnsafeRawPointer
        internal let count: Int
        
        internal func asUnsafeBytes() -> UnsafeRawBufferPointer {
            UnsafeRawBufferPointer(start: self.baseAddress, count: self.count)
        }
        
        internal func asUnsafeMutableBytes() -> UnsafeMutableRawBufferPointer {
            UnsafeMutableRawBufferPointer(
                start: UnsafeMutableRawPointer(mutating: self.baseAddress),
                count: self.count
            )
        }
        
        internal func compareBytes(to other: ByteBufferStorage.Region) -> Bool {
            guard self.count == other.count else {
                return false
            }
            
            return memcmp(self.baseAddress, other.baseAddress, self.count) == 0
        }
    }
    
    internal func region(in range: Range<Int>) -> ByteBufferStorage.Region {
        guard range.lowerBound >= 0, range.upperBound <= self.capacity else {
            fatalError("Range exceeds buffer capacity")
        }
        
        let regionAddress = self.baseAddress.advanced(by: range.lowerBound)
        return ByteBufferStorage.Region(baseAddress: regionAddress, count: range.count)
    }
}

extension ByteBufferStorage {
    internal struct CopyOptions: OptionSet {
        internal let rawValue: Int
        
        internal static let applyGrowthStrategy = ByteBufferStorage.CopyOptions(rawValue: 1 << 0)
    }
    
    internal func copyBytes(
        from source: some Sequence<UInt8>,
        at offset: Int = 0,
        options: ByteBufferStorage.CopyOptions = []
    ) -> Int {
        precondition(offset >= 0, "Byte offset cannot be less than zero")
        
        if let count = source.withContiguousStorageIfAvailable({
            self.copyMemory(from: UnsafeRawBufferPointer($0), at: offset, options: options)
        }) {
            return count
        }
        
        let newCapacity = offset + source.underestimatedCount
        let shouldApplyGrowthStrategy = options.contains(.applyGrowthStrategy)
        self.growCapacityIfNeeded(newCapacity, shouldApplyGrowthStrategy: shouldApplyGrowthStrategy)
        
        let destinationAddress = self.baseAddress.advanced(by: offset)
        let mutableBuffer = UnsafeMutableRawBufferPointer(
            start: destinationAddress,
            count: source.underestimatedCount
        )
        var (unwritten, initialized) = mutableBuffer.initializeMemory(as: UInt8.self, from: source)
        assert(initialized.count == source.underestimatedCount)
        
        var count = initialized.count
        while var byte = unwritten.next() {
            count += withUnsafeBytes(of: &byte, {
                self.copyMemory(from: $0, at: offset + count, options: options)
            })
        }
        
        return count
    }
    
    internal func copyMemory(
        from source: UnsafeRawBufferPointer,
        at offset: Int = 0,
        options: ByteBufferStorage.CopyOptions = []
    ) -> Int {
        precondition(offset >= 0, "Byte offset cannot be less than zero")
        
        guard let sourceAddress = source.baseAddress else {
            return 0
        }
        
        let newCapacity = offset + source.count
        let shouldApplyGrowthStrategy = options.contains(.applyGrowthStrategy)
        self.growCapacityIfNeeded(newCapacity, shouldApplyGrowthStrategy: shouldApplyGrowthStrategy)
        
        let destinationAddress = self.baseAddress.advanced(by: offset)
        memcpy(destinationAddress, sourceAddress, source.count)
        
        return source.count
    }
    
    internal func growCapacityIfNeeded(
        _ minimumCapacity: Int,
        shouldApplyGrowthStrategy: Bool = false
    ) {
        guard minimumCapacity > self.capacity else {
            return
        }
        
        var newCapacity = minimumCapacity
        if shouldApplyGrowthStrategy {
            newCapacity = calculateCapacityAfterGrowth(using: newCapacity)
        }
        
        self.reallocate(toCapacity: newCapacity)
    }
}

private func calculateCapacityAfterGrowth(using capacity: Int) -> Int {
    let halfOfCapacity = capacity >> 1
    let (newCapacity, overflow) = capacity.addingReportingOverflow(halfOfCapacity)
    
    guard newCapacity < .max, !overflow else {
        return .max
    }
    
    return newCapacity + (newCapacity ^ 1 == newCapacity - 1 ? 1 : 0)
}
