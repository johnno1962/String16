//
//  Index16.swift
//  String16
//
//  Created by John Holdsworth on 15/12/2024.
//  Copyright © 2024 John Holdsworth. All rights reserved.
//
//  Repo: https://github.com/johnno1962/String16.git
//

import Foundation
@_exported import StringIndex

extension NSRange {
    public init(_ range: Range<String16.IndexType>) {
        self = NSMakeRange(range.lowerBound.index,
           range.upperBound.index - range.lowerBound.index)
    }
}

extension Unicode {
    public struct UTF16Scalar: ExpressibleByUnicodeScalarLiteral,
                               CustomStringConvertible, Equatable {
        public typealias Element = UTF16.CodeUnit // UInt16
        public let value: Element
        public init(value: Element) {
            self.value = value
        }
        public init(unicodeScalarLiteral value: UnicodeScalar) {
            self.value = Element(value.value)
        }
        public var unicodeScalar: UnicodeScalar? { UnicodeScalar(value) }
        public var description: String { unicodeScalar.flatMap {
            String($0) } ?? "0x\(String(value, radix: 16))" }
        public var asciiScalar: UnicodeScalar? {
            return value < 128 ? unicodeScalar : nil
        }
    }

    public struct Index16: StringIndex.OffsetIndexable {
        public typealias StringType = String16
        public typealias OffsetType = String.OffsetImpl<Self>

        public static var clampIndex = false
        public static var failed = { (msg: String) -> Never in
            fatalError("String16: "+msg)
        }

        public var index: Int
        public static func < (lhs: Self, rhs: Self) -> Bool {
            return lhs.index < rhs.index
        }
        public static func nsRange(_ range: Range<Self>,
                                   in string: String) -> NSRange {
            return NSRange(range)
        }
        public static func myRange(from: Range<String.Index>,
                                   in string: String) -> Range<Self> {
            let range = NSRange(from, in: string)
            return Self(index: range.location) ..<
                Self(index: range.location+range.length)
        }
        public static func toRange(from: Range<Self>,
                                   in string: String) -> Range<String.Index>? {
            return Range<String.Index>(nsRange(from, in: string), in: string)
        }
        public static func string(in string: StringType) -> String {
            return String(string)
        }
        public static func start(in string: StringType) -> Self {
            return string.startIndex16
        }
        public static func end(in string: StringType) -> Self {
            return string.endIndex16
        }
        public func safeIndex(offsetBy: Int, in string: StringType) -> Self? {
            return Unicode.withBreakIterator(for: string) { breaker in
                var offset = offsetBy, index = self.index
                while offset < 0 && index > 0 {
                    index = breaker.preceedingBoundary(at: index)
                    offset += 1
                }
                while offset > 0 && index < string.count {
                    index = breaker.followingBoundary(at: index)
                    offset -= 1
                }
                return offset == 0 ? string.index16(at: index) : nil
            }
        }
    }
}
