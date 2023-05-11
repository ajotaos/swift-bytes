//
//  File.swift
//  
//
//  Created by Álvaro Ortiz on 5/10/23.
//

public enum Endianness {
    case little
    case big
    
    public static let host: Endianness = {
        let value: UInt32 = 0x1234_5678

        return value == value.bigEndian ? .big : .little
    }()
}
