//
//  CommentCreator.swift
//  
//
//  Created by Vaida on 9/18/21.
//  Copyright © 2021 Vaida. All rights reserved.
//

import Foundation
import NaturalLanguage

/// A creator that creates comments for the use of description.
///
/// # A suggested way of using this structure:
/// 1. Generate the `template`.
///
///        var creator = CommentCreator("func +(lhs: T, rhs: T) -> T")
///        print(creator.template)
///
/// 2. Paste whatever the `template` is into the command window.
/// 3. Fill in the code in blank, or any other additional markup.
struct CommentCreator {

    /// The `String` representation of the declaration.
    var content: String

    /// The summary of the description.
    var summary: String?

    /// The example of the description.
    var example: String?

    /// The additional notes of the description.
    ///
    /// - Note: Used to provide additional information.
    ///
    /// Example:
    ///
    ///     /// The sylvester matrix representation of two polynomials.
    ///     ///
    ///     /// - Note: In mathematics, a Sylvester matrix is a matrix associated to two univariate polynomials with coefficients in a field or a commutative ring.
    ///     func sylvesterMatrix(_ lhs: Polynomial, _ rhs: Polynomial) -> Matrix {}
    var note: String?

    /// Used to provide information about `nil`.
    ///
    /// - Note: Used to provide information about `nil`.
    ///
    /// Example:
    ///
    ///     /// Resize the `ImageRep` behind the `NSImage`.
    ///     ///
    ///     /// - Attention: The return value is `nil` if there is no representation behind the `NSImage`.
    ///     func resized(to newSize: NSSize) -> NSImage? {}
    var attention: String?

    /// The important notes of the description.
    ///
    /// - Important: This is only used for the important information.
    ///
    /// Example:
    ///
    ///     /// Resize the `ImageRep` behind the `NSImage`.
    ///     ///
    ///     /// - Important: The method should be rarely used. To change the size of a `NSImage`, use
    ///     ///
    ///     ///     NSImage().size = CGSize(x: Double, y: Double)
    ///     func resized(to newSize: NSSize) -> NSImage? {}
    var important: String?

    /// The method used of the function or what the function does in detail.
    ///
    /// Example:
    ///
    ///     /// Resize the `ImageRep` behind the `NSImage`.
    ///     ///
    ///     /// - Remark: The method changes the resolution of the `ImageRep` behind the image.
    ///     func resized(to newSize: NSSize) -> NSImage? {}
    var remark: String?

    /// The method used of the function or what the function does in detail.
    ///
    /// Example:
    ///
    ///     /// Resize the `ImageRep` behind the `NSImage`.
    ///     ///
    ///     /// - Remark: The method changes the resolution of the `ImageRep` behind the image.
    ///     func resized(to newSize: NSSize) -> NSImage? {}
    var remark2: String?

    /// The condition that is required for the passed arguments.
    ///
    /// Example:
    ///
    ///     /// Iteration over items in a given folder.
    ///     ///
    ///     /// - Precondition: The path needs to exist; cause fatal error otherwise.
    ///     func iterationOverFolder(at path: String, exclude: [String]? = nil, action: ((String) -> Void)) {}
    var precondition: String?

    /// The descriptions for the parameters.
    ///
    /// Example:
    ///
    ///     /// Resize the `ImageRep` behind the `NSImage`.
    ///     ///
    ///     /// - Parameters:
    ///     ///   - newSize: the changed size of image
    ///     func resized(to newSize: NSSize) -> NSImage? {}
    var parameters: [String: String] = [:]

    /// Used to provide mathematical definition.
    var invariant: String?

    /// The descriptions for the return value.
    ///
    /// Example:
    ///
    ///     /// Resize the `ImageRep` behind the `NSImage`.
    ///     ///
    ///     /// - Returns: The `NSImage`, which is resized
    ///     func resized(to newSize: NSSize) -> NSImage? {}
    var returnValues: [String:String] = [:]

    /// The type of the declaration.
    var type: DeclarationType {
        if content.split(separator: " ").contains("func") {
            return .function
        } else if content.split(separator: " ").contains("struct") || content.split(separator: " ").contains("class") {
            return .structure
        } else if content.split(separator: " ").contains("var") || content.split(separator: " ").contains("let") {
            return .variable
        } else if content.split(separator: " ").contains("enum") {
            return .enumeration
        } else if content.split(separator: " ").contains("init") {
            return .initialization
        } else if content.split(separator: " ").contains("subscript") {
            return .subscript
        } else {
            if content.contains("init") {
                return .initialization
            } else if content.contains("subscript") {
                return .subscript
            }
            fatalError("Please consider \(self.content)")
        }
    }

    /// The template used for creating comment.
    var template: String {
        print()
        print("----- Template -----")
        print()

        if self.type == .function {
            var functionName = self.content.split(separator: " ")[self.content.split(separator: " ").firstIndex(of: "func")! + 1]
            functionName = functionName[functionName.startIndex..<functionName.firstIndex(of: "(")!]

            let parameters = {()->[String]? in
                let parameterField = {()-> String in
                    var content = ""
                    var lhsBracketCounter = 0
                    var rhsBracketCounter = 0

                    for i in self.content {
                        if i == "(" {
                            lhsBracketCounter += 1
                        } else if i == ")" {
                            rhsBracketCounter += 1
                        }

                        content += String(i)

                        if lhsBracketCounter == rhsBracketCounter && lhsBracketCounter != 0 {
                            break
                        }
                    }

                    return String(content[content.index(after: content.firstIndex(of: "(")!)..<(content.lastIndex(of: ")") ?? content.endIndex)])
                }()

                guard !parameterField.isEmpty else { return nil }

                let rawParameters = parameterField.components(separatedBy: ", ")
                var parameters: [String] = []

                for i in rawParameters {
                    let lhs = i.split(separator: ":").first!
                    if lhs.split(separator: " ").count == 1 {
                        parameters.append(String(lhs.split(separator: " ").first!))
                    } else {
                        parameters.append(String(lhs.split(separator: " ").last!))
                    }
                }

                return parameters
            }()

            let returnValue = {()->String? in
                if self.content.contains("->") {
                    let content = self.content.components(separatedBy: "->").last!
                    if content.contains("(") {
                        return String(content[content.index(after: content.firstIndex(of: "(")!)..<content.lastIndex(of: ")")!])
                    } else {
                        return content
                    }
                } else {
                    return nil
                }
            }()

            let isReturnValueOptional = returnValue?.contains("?")

            var content = ""
            if returnValue != nil {
                if returnValue!.contains("Bool") {
                    content.append("creator.summary = \"Determines whether <#T##content: String##String#>\"\n")
                } else if functionName.contains("find") {
                    content.append("creator.summary = \"Finds <#T##content: String##String#>\"\n")
                } else {
                    content.append("creator.summary = \"<#T##content: String##String#>\"\n")
                }
            } else {
                content.append("creator.summary = \"<#T##content: String##String#>\"\n")
            }
            content.append("""
                creator.example = \"\"\"


                           \"\"\"\n
                """)
            if isReturnValueOptional != nil && isReturnValueOptional! { content.append("creator.attention = \"The return value is `nil` if <#T##content: String##String#>\"\n") }
            if let parameters = parameters { for i in parameters { content.append("creator.parameters[\"\(i)\"] = \"<#T##content: String##String#>\"\n") } }

            if let returnValue = returnValue {
                if returnValue.contains(",") {
                    for i in returnValue.split(separator: ",") {
                        let name = i.components(separatedBy: ": ").first!
                        content.append("creator.returnValues[\"\(name.replacingOccurrences(of: " ", with: ""))\"] = \"<#T##content: String##String#>\"\n")
                    }
                } else {
                    if returnValue.contains("Bool") {
                        content.append("creator.returnValues[\"\"] = \"`true` if <#T##content: String##String#>; `false` otherwise.\"\n")
                    } else if isReturnValueOptional! {
                        content.append("creator.returnValues[\"\"] = \"<#T##content: String##String#>; `nil` otherwise.\"\n")
                    } else {
                        content.append("creator.returnValues[\"\"] = \"<#T##content: String##String#>\"\n")
                    }
                }
            }

            content.append("print(creator.creation)\n")
            content.append("\n")

            return content
        } else if self.type == .initialization {
            let isInitializationOptional = self.content.split(separator: "(").first!.contains("?")

            let parameters = {()->[String]? in
                let parameterField = {()-> String in
                    var content = ""
                    var lhsBracketCounter = 0
                    var rhsBracketCounter = 0

                    for i in self.content {
                        if i == "(" {
                            lhsBracketCounter += 1
                        } else if i == ")" {
                            rhsBracketCounter += 1
                        }

                        content += String(i)

                        if lhsBracketCounter == rhsBracketCounter && lhsBracketCounter != 0 {
                            break
                        }
                    }

                    return String(content[content.index(after: content.firstIndex(of: "(")!)..<content.endIndex])
                }()

                guard !parameterField.isEmpty else { return nil }

                let rawParameters = parameterField.components(separatedBy: ", ")
                var parameters: [String] = []

                for i in rawParameters {
                    let lhs = i.split(separator: ":").first!
                    if lhs.split(separator: " ").count == 1 {
                        parameters.append(String(lhs.split(separator: " ").first!))
                    } else {
                        parameters.append(String(lhs.split(separator: " ").last!))
                    }
                }

                return parameters
            }()

            var content = ""
            content.append("creator.summary = \"Creates an instance <#T##content: String##String#>\"\n")
            content.append("""
                creator.example = \"\"\"


                           \"\"\"\n
                """)
            if isInitializationOptional { content.append("creator.attention = \"The initialization fails if <#T##content: String##String#>\"\n") }
            if let parameters = parameters { for i in parameters { content.append("creator.parameters[\"\(i)\"] = \"<#T##content: String##String#>\"\n") } }

            content.append("print(creator.creation)")

            return content
        } else if self.type == .enumeration {

            var content = ""
            content.append("creator.summary = \"An enumeration of <#T##content: String##String#>\"\n")
            content.append("""
                creator.note = \"\"\"
                           The cases of this enumeration:

                                case <#T##content: String##String#>
                           \"\"\"\n
                """)

            content.append("print(creator.creation)\n")
            content.append("\n")

            return content
        } else if self.type == .structure {

            var content = ""
            content.append("creator.summary = \"A <#T##content: String##String#> that <#T##content: String##String#>\"\n")

            content.append("print(creator.creation)")

            return content
        } else if self.type == .subscript {

            let returnValue = {()->String? in
                if self.content.contains("->") {
                    return self.content.components(separatedBy: "->").last!
                } else {
                    return nil
                }
            }()

            let isReturnValueOptional = returnValue?.contains("?")

            var content = ""
            content.append("creator.summary = \"Accesses the `index`th element.\"\n")
            content.append("""
                creator.example = \"\"\"


                           \"\"\"\n
                """)
            if isReturnValueOptional! { content.append("creator.attention = \"The return value is `nil` if <#T##content: String##String#>\"\n") }
            content.append("creator.parameters[\"index\"] = \"The index of the collection.\"\n")
            if returnValue != nil {
                if isReturnValueOptional! {
                    content.append("creator.returnValues[\"\"] = \"The element at the `index`; `nil` otherwise.\"\n")
                } else {
                    content.append("creator.returnValues[\"\"] = \"The element at the `index`.\"\n")
                }
            }

            content.append("print(creator.creation)\n")
            content.append("\n")

            return content
        } else if self.type == .variable {

            let returnValue = {()->String? in
                if self.content.contains(": ") {
                    return self.content.components(separatedBy: ": ").last!
                } else {
                    return nil
                }
            }()

            let isReturnValueOptional = returnValue?.contains("?")

            var content = ""

            if returnValue != nil {
                if returnValue!.contains("Bool") {
                    content.append("creator.summary = \"Determine whether <#T##content: String##String#>\"\n")
                } else {
                    content.append("creator.summary = \"<#T##content: String##String#>\"\n")
                }
            }

            if isReturnValueOptional! { content.append("creator.attention = \"The return value is `nil` if <#T##content: String##String#>\"\n") }

            content.append("print(creator.creation)\n")
            content.append("\n")

            return content
        } else {
            fatalError()
        }
    }

    var creation: String {
        print("----- Creation -----")
        print()
        // In the order of summary, important, precondition, example, remark, invariant, note, attention, link, parameters, returns
        var content = ""
        let summary = self.summary!.formalized()
        var summarySplit = summary.split(separator: " ")
        let first = summarySplit.removeFirst()
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = String(first)
        //            print(tagger.tag(at: String(first).startIndex, unit: .word, scheme: .lemma).0?.rawValue)
        if tagger.tag(at: String(first).startIndex, unit: .word, scheme: .lemma).0?.rawValue == String(first).lowercased() {
            print("Please add 's' for the summary.")
            exit(1)
        }

        content.append("/// \(summary)\n")
        content.append("///\n")

        if let important = important {
            content.append("/// - Important: \(important.formalized())\n")
            content.append("///\n")
        }
        if let precondition = precondition {
            content.append("/// - Precondition: \(precondition.formalized())\n")
            content.append("///\n")
        }

        if let example = example {
            content.append("/// **Example** \n")
            content.append("///\n")

            for i in example.split(separator: "\n") {
                var value = "///  \(i)\n"
                while value[value.index(value.startIndex, offsetBy: 3)] == " " { value.remove(at: value.index(value.startIndex, offsetBy: 3)) }
                for _ in 0..<5 { value.insert(" ", at: value.index(value.startIndex, offsetBy: 3)) }
                content.append(value)
            }

            content.append("///\n")
        }

        if let remark = remark {
            content.append("/// - Remark: \(remark.formalized())\n")
            content.append("///\n")
        }

        if let remark = remark2 {
            content.append("/// - Remark: \(remark.formalized())\n")
            content.append("///\n")
        }

        if let invariant = self.invariant {
            content.append("/// - Invariant: \(invariant.formalized())\n")
            content.append("///\n")
        }

        if let note = note {
            content.append("/// - Note: \(note.formalized())\n")
            content.append("///\n")
        }

        if let attention = attention {
            content.append("/// - Attention: \(attention.formalized())\n")
            content.append("///\n")
        }

        if !parameters.isEmpty {
            content.append("/// - Parameters:\n")
            for i in parameters {
                content.append("///    - \(i.key): \(i.value.formalized())\n")
            }

            content.append("///\n")
        }

        if !self.returnValues.isEmpty {
            if self.returnValues.count == 1 {
                content.append("/// - Returns: \(self.returnValues.first!.value.formalized())\n")
                content.append("///\n")
            } else {
                content.append("/// - Returns:\n")
                var length = self.returnValues.keys.map({ $0.count }).sorted(by: >).first!
                length += 4 + "///   ".count + 3
                for i in self.returnValues {
                    var value = ""
                    value.append("///   `\(i.key) `")
                    while value.count < length {
                        value += " "
                    }
                    value += i.value.formalized()
                    content.append(value + "\n")
                    content.append("///\n")
                }
            }
        }

        for _ in 0..<3 { content.remove(at: content.lastIndex(of: "/")!) }
        content.removeLast()

        return content
    }

    /// A enumeration of the types of declaration in Swift.
    enum DeclarationType {
        case function, structure, variable, enumeration, initialization, `subscript`
    }

    /// Creates an instance with the declaration.
    init(_ content: String) {
        if content.contains("{") {
            self.content = content
            self.content.remove(at: content.firstIndex(of: "{")!)
        } else {
            self.content = content
        }
    }

}


