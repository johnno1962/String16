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
    public init?<S: StringProtocol>(
        _ range: Range<String16.IndexType>, in string: S) {
        self = NSMakeRange(range.lowerBound.index,
           range.upperBound.index - range.lowerBound.index)
    }
}

extension String16 {
    public struct Index16: OffsetIndexable {
        public var index: Int
        public typealias StringType = String16
        public typealias OffsetType = String.OffsetImpl<Self>
        public static func < (lhs: Self, rhs: Self) -> Bool {
            return lhs.index < rhs.index
        }
        public static func nsRange(_ range: Range<Self>,
            in string: String) -> NSRange {
            return NSMakeRange(range.lowerBound.index,
                range.upperBound.index - range.lowerBound.index)
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
        public func indexBefore(in string: StringType) -> Self {
            return string.index16(before: self)
        }
        public func indexAfter(in string: StringType) -> Self {
            return string.index16(after: self)
        }
        public func safeIndex(offsetBy: Int = 1, in string: StringType) -> Self? {
            var offset = offsetBy, index = self.index
            return string.withBreakIterator { breaker in
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
