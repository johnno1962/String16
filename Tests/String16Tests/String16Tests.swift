import XCTest
import Foundation
@testable import String16

final class String16Tests: XCTestCase {
    func XCTAssertEqual(_ a: String16, _ b: String) {
        XCTAssertTrue(a.stringValue == b)
    }
    func XCTAssertEqual<T: Equatable>(_ a: T, _ b: T) {
        XCTAssertTrue(a == b)
    }
    func testExample() {
       // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        var str = String16("Hello, World!")
        str.insert("?", at: str.endIndex-1)
        XCTAssertEqual(str, "Hello, World?!")
        print(str[.first(of: " ")...])
        str[.first(of: "o")+1 + .first(of: "o")] = "a"
        XCTAssertEqual(str, "Hello, Warld?!")
        str[.start+1] = "o"
        XCTAssertEqual(str[..<(.first(of: " "))], "Hollo,")
        XCTAssertEqual(str[(str.endIndex16-2)...], "?!")
        
        for i in 1...str.count {
            XCTAssertEqual(str[str.index(str.endIndex, offsetBy: -i)],
                           str[str.endIndex-i])
        }
        
        str.insert(".", at: .end+0+0)
        XCTAssertEqual(str, "Hollo, Warld?!.")
        
        XCTAssertEqual(str[.start+2 ..< .end-2], "llo, Warld?")
        XCTAssertEqual(str[..<(.first(of:" "))], "Hollo,")
        XCTAssertEqual(str[(.last(of: " ")+1)...], "Warld?!.")
        
        let fifthChar: Character = str[.start+4]
        let firstWord = str[..<(.first(of:" "))]
        let stripped = str[.start+1 ..< .end-1]
        let lastWord = str[(.last(of: " ")+1)...]
        
        XCTAssertEqual(fifthChar, "o")
        XCTAssertEqual(firstWord, "Hollo,")
        XCTAssertEqual(stripped, "ollo, Warld?!")
        XCTAssertEqual(lastWord, "Warld?!.")
        
//            XCTAssertEqual(str.stringValue.range(of: "l",
//                                     range: Range(.first(of: "W") ..< .end,
//                                                  in: str)!)?.lowerBound,
//                           str.index(of:.last(of: "l")))

        XCTAssertEqual(str.index(of: .either(.first(of: "z"),
                                             or: .first(of: "W"))),
                       str.index(of: .first(of: "W")))
        
        str[..<(.first(of: " "))] = "Hi,"
        str[.last(of:"a")] = "o"
        XCTAssertEqual(str, "Hi, World?!.")
        XCTAssertEqual(str[(.last(of: " ")+1)...], "World?!.")
        
        XCTAssertEqual(str[.first(of: #"\w+"#, regex: true, end: false)], "H")
        XCTAssertEqual(str[.first(of: #"\w+"#, regex: true, end: true)], ",")
        XCTAssertEqual(str[.last(of: #"\w+"#, regex: true, end: false)], "W")
        XCTAssertEqual(str[.last(of: #"\w+"#, regex: true, end: true)], "?")
        
        XCTAssertEqual(str[.first(of: #"\w+"#, regex: true, end: true) ..<
            .last(of: #"\w+"#, regex: true)], ", ")
        
        XCTAssertEqual(str[..<(.first(of:#"\w+"#, regex: true, end: true) +
            .first(of:#"\w+"#, regex: true, end: true))],
                       "Hi, World")
        
        XCTAssertNil(str[safe: .start-1])
        XCTAssertNil(str[safe: .end+1])
        XCTAssertNil(str[safe: .last(of: "🤠")])
        XCTAssertNil(str[safe: ..<(.first(of: "z"))])
        
        XCTAssertEqual(str.index(of: .start), str.startIndex16)
        XCTAssertEqual(str.index(of: .first(of: " "))?.index, str.firstIndex(of: " "))
        
        str[.end] = "🤡" // append
        XCTAssertEqual(str, "Hi, World?!.🤡")
        print(str, str.stringValue)

        var string = String16("Hello World")
        let char = string[.start+1] // "e"
        XCTAssertEqual(char, "e")
        string[.start+7] = "a" // "Hello Warld"
        XCTAssertEqual(string, "Hello Warld")
    }
}
