//
//  String16.swift
//  String16
//
//  Created by John Holdsworth on 15/12/2024.
//  Copyright © 2024 John Holdsworth. All rights reserved.
//
//  Repo: https://github.com/johnno1962/String16.git
//

import Foundation

public typealias String16 = Array<String.UTF16Scalar>

extension String {
    public init(_ s: String16) {
        self = s.stringValue
    }
    public init(_ s: ArraySlice<String.UTF16Scalar>) {
        self = s.stringValue
    }
    public struct UTF16Scalar: ExpressibleByUnicodeScalarLiteral,
                               CustomStringConvertible, Equatable {
        public typealias Element = UTF16View.Element
        public static var failed = { (msg: String) in
            fatalError(msg)
        }
        public static var clampIndex = false
        public let value: Element
        public init(value: Element) {
            self.value = value
        }
        public init(unicodeScalarLiteral value: UnicodeScalar) {
            self.value = Element(value.value)
        }
        public var description: String { unicodeScalar.flatMap {
            String($0) } ?? "0x\(String(value, radix: 16))" }
        public var unicodeScalar: UnicodeScalar? { UnicodeScalar(value) }
        public var asciiScalar: UnicodeScalar? {
            return value < 128 ? unicodeScalar : nil
        }
    }
}

extension String16 {
    public typealias IndexType = Index16
    public typealias UTF16Scalar = String.UTF16Scalar

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
    func fail<T>(_ msg: String) -> T {
        UTF16Scalar.failed(msg)
    }
    
    func withBreakIterator<T>(body: @escaping (CharacterBreaker) -> T) -> T {
        return withElementBuffer {
            let dictKey = "\(Self.self)"
            var sharedBI = Thread.current
                .threadDictionary[dictKey] as? CharacterBreaker
            if sharedBI == nil {
                sharedBI = CharacterBreaker(buffer: $0, count: self.count)
                Thread.current.threadDictionary[dictKey] = sharedBI
            } else {
                sharedBI?.setText(buffer: $0, count: self.count)
            }
            return body(sharedBI ?? self.fail("No iterator??"))
        }
    }
    
    public var startIndex16: IndexType {
        return index16(at: 0)
    }
    public var endIndex16: IndexType {
        return index16(at: count)
    }
    public func index16(at: Int) -> IndexType {
        #if DEBUG
        withBreakIterator { breaker in
            if !breaker.isBoundary(at: at) {
                NSLog("\(Self.self): Creating invalid index at: \(at)")
            }
        }
        #endif
        return Index16(index: at)
    }
    public func index16(before i: IndexType) -> IndexType {
        let before = i.safeIndex(offsetBy: -1, in: self)
        return (UTF16Scalar.clampIndex ? before ?? i : before)
                ?? fail("No index before \(i)")
    }
    public func index16(after i: IndexType) -> IndexType {
        let after = i.safeIndex(offsetBy: 1, in: self)
        return (UTF16Scalar.clampIndex ? after ?? i : after)
                ?? fail("No index after \(i)")
    }
    public var characterIndices: AnySequence<IndexType> {
        return AnySequence(Index16Iterator(string: self))
    }
    public var characters: AnySequence<Character> {
        return AnySequence(CharacterIterator(
            indices: Index16Iterator(string: self)))
    }
    func validate(range: Range<IndexType>) {
        withBreakIterator { breaker in
            if range.lowerBound < startIndex16 ||
                !breaker.isBoundary(at: range.lowerBound.index) {
                UTF16Scalar.failed("Invalid lower bound \(range.lowerBound)")
            }
            if range.upperBound > endIndex16 ||
                !breaker.isBoundary(at: range.upperBound.index) {
                UTF16Scalar.failed("Invalid upper bound \(range.upperBound)")
            }
        }
    }
    public subscript (r: Range<IndexType>) -> String {
        get {
            validate(range: r)
            return Array(self[r.lowerBound.index..<r.upperBound.index]).stringValue
        }
        set(newValue) {
            validate(range: r)
            let replacement = newValue.utf16.map { UTF16Scalar(value: $0) }
            replaceSubrange(r.lowerBound.index..<r.upperBound.index,
                            with: replacement)
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
    struct Index16Iterator: Sequence, IteratorProtocol {
        let string: String16
        var index = Index16(index: 0)
        mutating public func next() -> IndexType? {
            if let next = index.safeIndex(in: string) {
                defer { index = next }
                return index
            }
            return nil
        }
    }
    struct CharacterIterator: Sequence, IteratorProtocol {
        var indices: Index16Iterator
        mutating public func next() -> Character? {
            return indices.next().flatMap { indices.string[$0] }
        }
    }
}

extension ArraySlice where Element == String.UTF16Scalar {
    public var stringValue: String { Array(self).stringValue }
}

#if false // Someday
extension String16: @retroactive StringProtocol {
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
