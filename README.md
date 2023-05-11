# Bytes

A simple Swift library for working with byte buffers.

## Installation

### Swift Package Manager

To use Bytes with Swift Package Manager, add the following line to the `dependencies` array in your `Package.swift` file:

```swift
.package(url: "https://github.com/ajotaos/swift-bytes.git", from: "1.0.0")
```

Then, add the `"Bytes"` dependency to your target:

```swift
.target(name: "MyTarget", dependencies: ["Bytes"])
```

## Usage

Here's a quick example showing how to create a `ByteBuffer`, write some bytes to it, and then read those bytes back:

```swift
var buffer = ByteBuffer()
buffer.write(bytes: [0x41, 0x42, 0x43])
let bytes = buffer.bytes(count: 3)
print(bytes) // Output: [65, 66, 67]
```

You can also write integers, floating-point numbers, and strings to a `ByteBuffer`:

```swift
var buffer = ByteBuffer()
buffer.write(integer: UInt32(1234))
buffer.write(floatingPoint: Float32(3.14))
buffer.write(string: "hello")
```

To read these values back, you can use the corresponding `integer`, `floatingPoint`, and `string` methods:

```swift
let int: Int = buffer.integer(as: UInt32.self)
let float: Float = buffer.floatingPoint(as: Float32.self)
let string: String = buffer.string(count: 5)
```

## Unsafe Access

Bytes provides a couple of methods that allow for unsafe access to the raw bytes of a `ByteBuffer`. These methods are `withUnsafeBytes` and `withUnsafeMutableBytes`. Use these methods with care, as they can easily lead to undefined behavior if used incorrectly.

Here's an example of how to use `withUnsafeBytes`:

```swift
let buffer = ByteBuffer(bytes: [0x41, 0x42, 0x43])
let count = buffer.withUnsafeBytes { bytes in
    let ptr = bytes.bindMemory(to: UInt8.self).baseAddress!
    // Do something with the raw bytes here
    return bytes.count
}
print(count) // Output: 3
```

## License

Bytes is released under the MIT license. See [LICENSE](LICENSE) for details.
