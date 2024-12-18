//
//  Subscripts.swift
//  String16
//
//  Created by John Holdsworth on 15/12/2024.
//  Copyright © 2024 John Holdsworth. All rights reserved.
//
//  Repo: https://github.com/johnno1962/String16.git
//

extension String16 {
    public typealias OffsetIndex = IndexType.OffsetType
    public typealias OISubstring = String // Can/should? be Substring
    public typealias OOISubstring = OISubstring? // "safe:" prefixed subscripts
    
    public func index(of: OffsetIndex) -> IndexType? {
        return of.index(in: self)
    }

    /// Subscripts on StringProtocol for OffsetIndex type
    public subscript (offset: OffsetIndex) -> Character {
        get {
            guard let result = self[safe: offset] else {
                fatalError("Invalid offset index \(offset), \(#function)")
            }
            return result
        }
        set (newValue) {
            guard let start = offset.index(in: self) else {
                fatalError("Invalid offset index \(offset), \(#function)")
            }
            // Assigning Chacater to endIndex is an append.
            let end = start + (start < IndexType.end(in: self) ? 1 : 0)
            self[start ..< end] = OISubstring(String(newValue))
        }
    }

    // lhs ..< rhs operator
    public subscript (range: Range<OffsetIndex>) -> OISubstring {
        get {
            guard let result = self[safe: range] else {
                fatalError("Invalid range of offset index \(range), \(#function)")
            }
            return result
        }
        set (newValue) {
            guard let from = range.lowerBound.index(in: self),
                  let to = range.upperBound.index(in: self) else {
                fatalError("Invalid range of offset index \(range), \(#function)")
            }
            let before = self[..<from.index], after = self[to.index...]
            self = Self(before.stringValue + String(newValue) + after.stringValue)
        }
    }
    // ..<rhs operator
    public subscript (range: PartialRangeUpTo<OffsetIndex>) -> OISubstring {
        get { return self[.start ..< range.upperBound] }
        set (newValue) { self[.start ..< range.upperBound] = newValue }
    }
    // lhs... operator
    public subscript (range: PartialRangeFrom<OffsetIndex>) -> OISubstring {
        get { return self[range.lowerBound ..< .end] }
        set (newValue) { self[range.lowerBound ..< .end] = newValue }
    }

    // =================================================================
    // "safe" nil returning subscripts on StringProtocol for OffsetIndex
    // from:  https://forums.swift.org/t/optional-safe-subscripting-for-arrays
    public subscript (safe offset: OffsetIndex) -> Character? {
        get { return offset.index(in: self).flatMap { self[$0] } }
        set (newValue) { self[offset] = newValue! }
    }
    // lhs ..< rhs operator
    public subscript (safe range: Range<OffsetIndex>) -> OOISubstring {
        get {
            guard let from = range.lowerBound.index(in: self),
                  let to = range.upperBound.index(in: self),
                from <= to else { return nil }
            return OISubstring(self[from ..< to])
        }
        set (newValue) { self[range] = newValue! }
    }
    // ..<rhs operator
    public subscript (safe range: PartialRangeUpTo<OffsetIndex>) -> OOISubstring {
        get { return self[safe: .start ..< range.upperBound] }
        set (newValue) { self[range] = newValue! }
    }
    // lhs... operator
    public subscript (safe range: PartialRangeFrom<OffsetIndex>) -> OOISubstring {
        get { return self[safe: range.lowerBound ..< .end] }
        set (newValue) { self[range] = newValue! }
    }

    // =================================================================
    // Misc.
    public mutating func replaceSubrange<C>(_ bounds: Range<OffsetIndex>,
        with newElements: C) where C : Collection, C.Element == Character {
        self[bounds] = OISubstring(newElements)
    }
    public mutating func insert<S>(contentsOf newElements: S, at i: OffsetIndex)
        where S : Collection, S.Element == Character {
        replaceSubrange(i ..< i, with: newElements)
    }
    public mutating func insert(_ newElement: Character, at i: OffsetIndex) {
        insert(contentsOf: String(newElement), at: i)
    }
}
