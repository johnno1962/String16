# String16

In response to [this Swift evolution thread](https://forums.swift.org/t/subscripting-a-string-should-be-possible-or-have-an-easy-alternative/76416)
which asks the question "Why can't you just index into the characters of Swift's Strings?"
the is an exploration of whether you could represent Strings as "just an array"
while still having the option of maintaining Unicode Correctness if you opt in
by using a special index. The basic type is `String16` which you can initialise
from any StringProtocol and it literally is a Swift Array of 16 bit integers 
wrapped in a struct which controls how the elements are displayed.

Thereafter, you can index into or modify the Array any way you please but be 
aware that not all integer indexes represent the start of valid Unicoded
characters. For correct procesing, use the `String16.Index16` struct or 
better still the [StringIndex](https://github.com/johnno1962/StringIndex)
package has been integrated to use expressions such as the following:

```
    var string = String16("Hello World")
    let char = string[.start+1] // "e"
    string[.start+7] = "a" // "Hello Warld"
```

For exaples consult the tests. The Unicode segmentation taps into functionality in 
IBM's [ICU](https://unicode-org.github.io/icu-docs/apidoc/dev/icu4c/ubrk_8h.html) 
library and should be correct. As a bit of background here is an except from
the chapter on Unicode encodings from my iBook "Swift Secrets".

## Unicode and Swift’s String model

In this chapter, we’ll review the storied evolution of how text is represented in memory and the great simplification that the Swift “Character” model brings to the task.

### A long history
The history of computers being able support all the world’s character sets is as long as one might expect. It started with the 7 bit “American standard code for information interchange” (ASCII). This was fine if you happen to be American but soon, as computers rolled out across Europe, the eighth bit was pressed into service, resulting in the 8 bit “latin-1” encoding to represent European characters such as é and õ. This was followed by the idea of switching between different 8 bit “code pages” of characters for less common languages depending on the user. 

How then to cope with the “Big5” Asian encodings, each of which could have thousands of different characters in a single document. The first OS to feel the pinch as it rolled out internationally was Windows, which responded by defining the “wchar” type to be 16 bits. Soon after, it was realised even this was not enough, so a couple of empty code pages were pressed into service using a particular encoding (“utf-16”) to provide up to 20 bits (https://en.wikipedia.org/wiki/UTF-16). Thankfully, while this tendency to throw bits at the problem was taking place, a couple of gifted engineers came up with an efficient, variable length, backward compatible, byte-based encoding over dinner in 1992 https://www.cl.cam.ac.uk/~mgk25/ucs/utf-8-history.txt ("utf-8" https://en.wikipedia.org/wiki/UTF-8). The story didn’t end there, however, as the “zero width joiner” was introduced (e.g., in Unicode 9) in which an emoji followed by these invisible characters could also be followed by another emoji and these would be combined. An example of this is the family emojis: the members of a family are combined into a single “Unicode Grapheme Cluster” corresponding to a single visual entity on a screen.

### ASCII, utf-16 and utf-8 through to zero width joiners
What does this mean in terms of bits and bytes? If you add the following string into a Swift project you can begin to unpack all the detail that Swift’s clean “Character” type is protecting you from. Using a single test string that spans the history of Unicode character encoding we can see how characters are encoded.

```
var s = "Hello, Wórld 👨 🇮🇹 👨🏽 👨‍👨‍👧‍👦!”
```

Looking at the output of a first print statement we can pick out the ASCII codes of individual characters (in red) for the first word (“Hello”) and can verify this using “man ascii” manual page available from the command line.
```
print(s.utf8.map { "0x"+String($0, radix: 16) }.joined(separator: ", “))
0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x2c, 0x20, 0x57, 0xc3, 0xb3, 0x72, 0x6c, 0x64, 0x20, 0xf0, 0x9f, 0x91, 0xa8, 0x20, 0xf0, 0x9f, 0x87, 0xae, 0xf0, 0x9f, 0x87, 0xb9, 0x20, 0xf0, 0x9f, 0x91, 0xa8, 0xf0, 0x9f, 0x8f, 0xbd, 0x20, 0xf0, 0x9f, 0x91, 0xa8, 0xe2, 0x80, 0x8d, 0xf0, 0x9f, 0x91, 0xa8, 0xe2, 0x80, 0x8d, 0xf0, 0x9f, 0x91, 0xa7, 0xe2, 0x80, 0x8d, 0xf0, 0x9f, 0x91, 0xa6, 0x21
```

The second word, however, has a character from the eight bit latin-1 (a.k.a. ISO-8859-1) character encoding, outside the ASCII range (0x00—0x7f); it is encoded according to utf-8 as 0xc3, 0xb3. Looking at the utf-16 representation in a second print statement we can see this is the case and ó has the latin-1 8-bit code 0xf3:
```
print(s.utf16.map { "0x"+String($0, radix: 16) }.joined(separator: ", “))
0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x2c, 0x20, 0x57, 0xf3, 0x72, 0x6c, 0x64, 0x20, 0xd83d, 0xdc68, 0x20, 0xd83c, 0xddee, 0xd83c, 0xddf9, 0x20, 0xd83d, 0xdc68, 0xd83c, 0xdffd, 0x20, 0xd83d, 0xdc68, 0x200d, 0xd83d, 0xdc68, 0x200d, 0xd83d, 0xdc67, 0x200d, 0xd83d, 0xdc66, 0x21
```

Then, as we move to the use of emojis in the string, things become more opaque. We see 0xd8xx followed by 0xdxxx sequences. This is how characters that do not fit into an unsigned 16-bit value are represented in utf-16. It is time to shift up to the next abstraction in Swift: UnicodeScalar values.
```
print(s.unicodeScalars.map { "0x"+String($0.value, radix: 16) }.joined(separator: ", “))
0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x2c, 0x20, 0x57, 0xf3, 0x72, 0x6c, 0x64, 0x20, 0x1f468, 0x20, 0x1f1ee, 0x1f1f9, 0x20, 0x1f468, 0x1f3fd, 0x20, 0x1f468, 0x200d, 0x1f468, 0x200d, 0x1f467, 0x200d, 0x1f466, 0x21
```

You can see now the common early emoji values, starting with 0x1fxxxx. First, the “man” emoji  0x1f468 follows a “regional indicator” flag, a pair of values in the range 0x1f1e6 to 0x1f1ff corresponding to two unique letters identifying the region. Moving further through the string, post Unicode 9.0, you can see the man emoji again, but this time it is modified by following it with the medium skin tone modifier 0x1f3fd. Finally, in our trip through the Unicode universe, you can see the 0x200d “Zero width joiner” value used to combine two adult emojis, a girl emoji, and a boy emoji to create a single family emoji represented across 25 bytes. 
