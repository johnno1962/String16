//
//  Unicode.swift
//  String16
//
//  Created by John Holdsworth on 15/12/2024.
//  Copyright © 2024 John Holdsworth. All rights reserved.
//
//  Repo: https://github.com/johnno1962/String16.git
//
//  Related to Unicode segmenting indicies correctly. Taps into OS's ICU.
//  See: https://unicode-org.github.io/icu-docs/apidoc/dev/icu4c/ubrk_8h.html
//

import Foundation

extension Unicode {
    @available(OSX 10.12, *)
    private static let iteratorLock: os_unfair_lock_t = {
        let unfairLock: os_unfair_lock_t
        unfairLock = .allocate(capacity: 1)
        unfairLock.initialize(to: os_unfair_lock())
        return unfairLock
    }()
    
    static func withBreakIterator<T>(for string: String16, _ body:
                                     @escaping (CharacterBreaker) -> T) -> T {
        return string.withElementBuffer {
            let dictKey = "CharacterBreaker"
            if #available(OSX 10.12, *) {
                os_unfair_lock_lock(iteratorLock)
            }
            var sharedBI = Thread.current
                .threadDictionary[dictKey] as? CharacterBreaker
            if sharedBI == nil {
                sharedBI = CharacterBreaker(buffer: $0, count: string.count)
                Thread.current.threadDictionary[dictKey] = sharedBI
            } else {
                sharedBI?.setText(buffer: $0, count: string.count)
            }
            if #available(OSX 10.12, *) {
                os_unfair_lock_unlock(iteratorLock)
            }
            return body(sharedBI ?? string.fail("No iterator??"))
        }
    }

    class CharacterBreaker {
        let opened: UBreakIterator
        init?(buffer: UnsafePointer<UTF16Scalar.Element>, count: Int) {
            var status = 0
            guard let opened = Self.ubrk_open(
                Self.UBRK_CHARACTER, Locale.current.identifier,
                buffer, UInt32(count), &status) else { return nil }
            self.opened = opened
        }
        func setText(buffer: UnsafePointer<UTF16Scalar.Element>, count: Int) {
            var status = 0
            Self.ubrk_setText(opened, buffer, UInt32(count), &status)
        }
        func isBoundary(at: Int) -> Bool {
            return Self.ubrk_isBoundary(opened, UInt32(at))
        }
        func preceedingBoundary(at: Int) -> Int {
            return Int(Self.ubrk_preceding(opened, UInt32(at)))
        }
        func followingBoundary(at: Int) -> Int {
            return Int(Self.ubrk_following(opened, UInt32(at)))
        }
        func close() {
            Self.ubrk_close(opened)
        }
        
        // ICU interface
        typealias UBreakIterator = OpaquePointer
        static let UBRK_CHARACTER: UInt32 = 0

        static let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)
        static let ubrk_open = unsafeBitCast(dlsym(RTLD_DEFAULT, "ubrk_open"),
            to: (@convention(c) (_ type: UInt32, _ locale: UnsafePointer<CChar>,
                                 _ text: UnsafePointer<String.UTF16View.Element>,
                                 _ textLength: UInt32, _ status: UnsafeRawPointer?)
                 -> UBreakIterator?).self)
        static let ubrk_setText = unsafeBitCast(dlsym(RTLD_DEFAULT, "ubrk_setText"),
            to: (@convention(c) (_ bi: UBreakIterator,
                                 _ text: UnsafePointer<String.UTF16View.Element>,
                                 _ textLength: UInt32, _ status: UnsafeRawPointer?)
                 -> Void).self)
        static let ubrk_isBoundary = unsafeBitCast(dlsym(RTLD_DEFAULT, "ubrk_isBoundary"),
            to: (@convention(c) (_ bi: UBreakIterator, _ offset: UInt32) -> Bool).self)
        static let ubrk_preceding = unsafeBitCast(dlsym(RTLD_DEFAULT, "ubrk_preceding"),
            to: (@convention(c) (_ bi: UBreakIterator, _ offset: UInt32) -> UInt32).self)
        static let ubrk_following = unsafeBitCast(dlsym(RTLD_DEFAULT, "ubrk_following"),
            to: (@convention(c) (_ bi: UBreakIterator, _ offset: UInt32) -> UInt32).self)
        static let ubrk_close = unsafeBitCast(dlsym(RTLD_DEFAULT, "ubrk_close"),
            to: (@convention(c) (_ bi: UBreakIterator) -> Void).self)
    }
}
