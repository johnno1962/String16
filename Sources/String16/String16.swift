//
//  String16.swift
//  String16
//
//  Created by John Holdsworth on 15/12/2024.
//  Copyright © 2024 John Holdsworth. All rights reserved.
//
//  Repo: https://github.com/johnno1962/String16.git
//
//  Basic String16 data representation which is just an Array of UInt16s.
//

import Foundation

public typealias String16 = Array<Unicode.UTF16Scalar>

/// Bridging to String
extension String {
    public init(_ s: String16) {
        self = s.stringValue
    }
    public init(_ s: ArraySlice<String16.Element>) {
        self = s.stringValue
    }
    public var string16Value: String16 { String16(self) }
}

extension ArraySlice where Element == String16.Element {
    public var stringValue: String { Array(self).stringValue }
}

/// Extensions to create/access buffer.
extension String16 {
    public typealias UTF16Scalar = Element
    
    public init<S: StringProtocol>(_ s: S) {
        self = s.utf16.map { UTF16Scalar(value: $0) }
    }
    func withElementBuffer<T>(body: @escaping (UnsafePointer<UTF16Scalar.Element>) -> T) -> T {
        let callBody = { (bp: UnsafeBufferPointer<UTF16Scalar>) in bp.baseAddress?
                .withMemoryRebound(to: UTF16Scalar.Element.self, capacity: bp.count) {
                    return body($0) } ?? self.fail("No buffer??")
        }
        return withContiguousStorageIfAvailable(callBody) ?? withUnsafeBufferPointer(callBody)
    }
    public var stringValue: String {
        return withElementBuffer { NSString(characters: $0, length: self.count) as String }
    }
}

/// functionality related to indexing.
extension String16 {
    public typealias IndexType = Unicode.Index16
    func fail<T>(_ msg: String) -> T {
        IndexType.failed(msg)
    }

    public var startIndex16: IndexType {
        return IndexType(index: 0)
    }
    public var endIndex16: IndexType {
        return IndexType(index: count)
    }
    public func index16(at: Int) -> IndexType? {
        #if DEBUG
        guard Unicode.withBreakIterator(for: self, { breaker in
            if !breaker.isBoundary(at: at) {
                NSLog("String16: Creating invalid index at: \(at)")
                return false
            }
            return true
        }) else { return nil }
        #endif
        return IndexType(index: at)
    }
    public func index16(before i: IndexType) -> IndexType {
        let before = i.safeIndex(offsetBy: -1, in: self)
        return (IndexType.clampIndex ? before ?? i : before)
                ?? fail("No index before \(i)")
    }
    public func index16(after i: IndexType) -> IndexType {
        let after = i.safeIndex(offsetBy: 1, in: self)
        return (IndexType.clampIndex ? after ?? i : after)
                ?? fail("No index after \(i)")
    }
    func validate(range: Range<IndexType>, isSet: Bool = false) {
        #if DEBUG
        Unicode.withBreakIterator(for: self) { breaker in
            let doFail = isSet ? self.fail : { NSLog("String16: %@", $0) }
            if range.lowerBound < self.startIndex16 ||
                !breaker.isBoundary(at: range.lowerBound.index) {
                doFail("Invalid lower bound \(range.lowerBound)")
            }
            if range.upperBound > self.endIndex16 ||
                !breaker.isBoundary(at: range.upperBound.index) {
                doFail("Invalid upper bound \(range.upperBound)")
            }
        }
        #endif
    }
    public subscript (r: Range<IndexType>) -> String {
        get {
            validate(range: r)
            return self[r.lowerBound.index..<r.upperBound.index].stringValue
        }
        set(newValue) {
            validate(range: r, isSet: true)
            replaceSubrange(r.lowerBound.index..<r.upperBound.index,
                            with: String16(newValue))
        }
    }
    public subscript (i: IndexType) -> Character {
        get {
            return Character(self[i..<index16(after: i)])
        }
        set(newValue) {
            self[i..<index16(after: i)] = String(newValue)
        }
    }
    /// Iterators.
    public struct ScalarIterator: Sequence, IteratorProtocol {
        let string: String16
        var index = 0
        mutating public func next() -> UnicodeScalar? {
            guard index < string.count else { return nil }
            defer { self.index += 1 }
            if let scalar = string[index].unicodeScalar {
                return scalar
            }
            defer { self.index += 1 }
            let index = self.index
            return string.withElementBuffer { buffer in
                let unipair = UnsafeMutablePointer(mutating: buffer)+index
                return (NSString(charactersNoCopy: unipair, length: 2,
                            freeWhenDone: false) as String).unicodeScalars.first
            }
        }
    }
    public var unicodeScalars: AnySequence<UnicodeScalar> {
        return AnySequence(ScalarIterator(string: self))
    }
    struct Index16Iterator: Sequence, IteratorProtocol {
        let string: String16, stride: Int
        var index: IndexType
        mutating public func next() -> Range<IndexType>? {
            if let next = index.safeIndex(offsetBy: stride, in: string) {
                defer { index = next }
                return stride > 0 ? index ..< next : next ..< index
            }
            return nil
        }
    }
    public var characterRanges: AnySequence<Range<IndexType>> {
        return AnySequence(Index16Iterator(
            string: self, stride: 1, index: startIndex16))
    }
    struct CharacterIterator: Sequence, IteratorProtocol {
        var indices: Index16Iterator
        mutating public func next() -> Character? {
            return indices.next().flatMap { Character(indices.string[$0]) }
        }
    }
    public var characters: AnySequence<Character> {
        return AnySequence(CharacterIterator(indices: Index16Iterator(
            string: self, stride: 1, index: startIndex16)))
    }
    public var charactersReversed: AnySequence<Character> {
        return AnySequence(CharacterIterator(indices: Index16Iterator(
            string: self, stride: -1, index: endIndex16)))
    }
}

#if false // Someday
extension String16: StringProtocol {
    public typealias UTF8View = String.UTF8View
    public typealias UTF16View = String.UTF16View
    public typealias UnicodeScalarView = String.UnicodeScalarView
    
    public var utf8: String.UTF8View { stringValue.utf8 }
    public var utf16: String.UTF16View { stringValue.utf16 }
    public var unicodeScalars: String.UnicodeScalarView { stringValue.unicodeScalars }
    
    public func withCString<Result>(_ body: (UnsafePointer<CChar>) throws -> Result) rethrows -> Result {
        return try stringValue.withCString(body)
    }
    public func withCString<Result, Encoding>(encodedAs targetEncoding: Encoding.Type, _ body: (UnsafePointer<Encoding.CodeUnit>) throws -> Result) rethrows -> Result where Encoding : _UnicodeEncoding {
        return try stringValue.withCString(encodedAs: targetEncoding, body)
    }
}
#endif
