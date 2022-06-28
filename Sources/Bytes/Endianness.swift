public enum Endianness {
    case big
    case little

    public static let host: Endianness = {
        let value: UInt32 = 0x1234_5678

        return value == value.bigEndian ? .big : .little
    }()
}
