//
//  Log.swift
//  Municipium
//
//  Created by Roberto Previdi on 19/12/16.
//  Copyright © 2016 municipiumapp. All rights reserved.
//

import Foundation

public enum LogLevel:Int
{
	case error=0
	case info=1
	case debug=2
	case verbose=3
	public func toString()->String
	{
		switch self {
		case .error:
			return "E"
		case .info:
			return "I"
		case .debug:
			return "D"
		case .verbose:
			return "V"
		}
	}
	public func atLeast(_ level:LogLevel)->Bool
	{
		return rawValue>=level.rawValue
	}
	public func ifAtLeast(_ level:LogLevel,closure:()->())
	{
		if atLeast(level)
		{
			closure()
		}
	}
	
}

public typealias Splitter<T> = (/*previous:*/T,/*current:*/T)->Bool

extension Collection  {
	public func split(by splitter:Splitter<Self.Iterator.Element>) -> [Self.SubSequence]
	{
		var subSequences=Array<Self.SubSequence>()
		var it=startIndex
		var tokenStart=it
		while it != endIndex {
			let prev=self[it]
			it=index(after: it)
			if it==endIndex || splitter(prev,self[it]) {
				subSequences.append(self[tokenStart..<it])
				tokenStart=it
			}
		}
		return subSequences
	}
}

extension String {
	func toField(_ length:Int,separator:String=" ")->String {
		return padding(toLength: length-1, withPad: " ", startingAt: 0)+separator
	}
	
	func toMultilineField(_ length:Int,separator:String=" ",wrapMode:WrapMode = .wordWrap)->MultilineString
	{
		return MultilineSingleString(string:self,length:length,separator:separator,wrapMode:wrapMode)
	}
	func split(length:Int)->[String] {
		var cursor=startIndex
		var ret=[String]()
		repeat {
			if let rangeEnd=index(cursor,offsetBy:length,limitedBy:endIndex) {
				ret.append(substring(with: cursor..<rangeEnd))
				cursor=rangeEnd
			} else {
				if cursor != endIndex {
					ret.append(substring(from: cursor))
				}
				return ret
			}
		} while true
		
	}
	
}


protocol MultilineString {
	var length:Int {get}
	func toLines()->[String]
	func toString()->String
}

extension MultilineString {
	func toString()->String {
		return toLines().joined(separator: "\n")
	}
}

enum WrapMode {
	case noWrap
	case wordWrap
	case camelCaseWrap
	
	/// return "rows of tokens"
	func tokenize(s:String)->[[String]]
	{
		let splitter:Splitter<UnicodeScalar>={return $0.0=="\n"}
		let rows=s.unicodeScalars.split(by: splitter).map{String($0)}
		return rows.map(tokenizeRow)
	}
	
	func tokenizeRow(s:String)->[String] {
		switch self {
		case .noWrap:
			if true {
				let tokens=s.unicodeScalars.split(by: {
					(prev,curr) in
					return
					prev=="\n"
				}).map {String($0)}
				return tokens
			}
		case .wordWrap:
			if true {
				let splitter:Splitter<UnicodeScalar>={
					(prev:UnicodeScalar,curr:UnicodeScalar) in
					return
					(prev==" " && curr != " ") ||
						prev=="\n" ||
						prev==","
				}
				let tokens:[String]=s.unicodeScalars.split(by: splitter).map {String($0)}
				return tokens
			}
		case .camelCaseWrap:
			if true {
				let splitter:Splitter<UnicodeScalar>={
					(prev:UnicodeScalar,curr:UnicodeScalar) in
					return
					(prev==" " && curr != " ") ||
						prev=="\n" ||
						prev=="," ||
						(CharacterSet.lowercaseLetters.contains(prev) && CharacterSet.uppercaseLetters.contains(curr))
				}
				let tokens:[String]=s.unicodeScalars.split(by: splitter).map {String($0)}
				return tokens
			}
		}
	}
}

struct MultilineSingleString:MultilineString {
	let source:String
	let length:Int
	let separator:String
	let wrapMode:WrapMode
	init(string:String,length:Int,separator:String=" ",wrapMode:WrapMode = .wordWrap){
		source=string
		self.length=length
		self.separator=separator
		self.wrapMode=wrapMode
	}
	
	func toLines()->[String] {
		//		var cursor=source.startIndex
		var ret=[String]()
		var rowsOfTokens=wrapMode
			.tokenize(s: source)
			.map{
				$0.map {$0.replacingOccurrences(of: "\n", with: "")}
					.flatMap {$0.split(length:length-1)}}

		for row in rowsOfTokens {
		var s=""
			for token in row {
				let tokL=token.characters.count
				if s.characters.count+tokL<=length-1 {
					s=s+token
				} else {
					ret.append(s.toField(length,separator:separator))
					s=token
				}
			}
			ret.append(s.toField(length,separator:separator))
		}
		return ret
	}
}

func +(a:AggregateMultilineString,b:MultilineSingleString)->MultilineString
{
	var elements=a.elements
	elements.append(b)
	return AggregateMultilineString(elements: elements)
}
func +(a:MultilineSingleString,b:AggregateMultilineString)->MultilineString
{
	var elements:[MultilineString]=[a]
	elements.append(contentsOf:b.elements)
	return AggregateMultilineString(elements: elements)
}

func +(a:AggregateMultilineString,b:AggregateMultilineString)->MultilineString
{
	var elements=a.elements
	elements.append(contentsOf: b.elements)
	return AggregateMultilineString(elements: elements)
}

func +(a:MultilineString,b:MultilineString)->MultilineString
{
	return AggregateMultilineString(elements: [a,b])
}

/// transforms [[a,b,c],[1,2,3]] in [[a,1],[b,2],[c,3]]
/// all subarrays must have the same size, no bound checking
func invert<T>(array:[[T]])->[[T]] {
	var ret=[[T]]()
	var i=0
	for i in 0..<(array.first?.count ?? 0) {
		var line=[T]()
		for subarray in array {
			line.append(subarray[i])
		}
		ret.append(line)
	}
	return ret
}


struct AggregateMultilineString:MultilineString {
	let elements:[MultilineString]
	var length:Int {
		return elements.reduce(0){$0+$1.length}
	}
	func toLines()->[String] {
		var someOutput=false
		let allLines=elements
			.map{($0.length,$0.toLines())}
		guard let maxLinesNumber=allLines.map({ $0.1.count }).max() else {return [String]()}
		return
			
			invert(array:allLines
				.map { (length,_lines) in
					var lines=_lines
					while lines.count<maxLinesNumber {
						lines.append("".toField(length))
					}
					return lines
			})
				.map { $0.joined() }
	}
}

public struct LogEntry {
	public let tags:[String]
	public let level:LogLevel
	public let message:String
	public let timestamp:Date
	
	public static var toString:(LogEntry, Int)->String={ e,lineLength in
		let tags=e.tags.joined(separator:",")
		let multilineString=e.level.toString().toMultilineField(2) +
			"\(tags)".toMultilineField(16,wrapMode:.camelCaseWrap) +
			e.message.toMultilineField(lineLength-18)
		return multilineString.toString()
	}
}

public class LogManager {
	public init(){}
	public var entries=[LogEntry]()
	
	public var consoleFilter:(LogEntry)->Bool = {_ in return true}
	public var consoleLineLength=140
	
	public typealias OnLogAction=(LogEntry)->Void
	public var onLogActions=[OnLogAction]()
	
	public func log(_ message:String,_ tags:[String]) {
		log(message,tags,.debug)
	}
	
	public func log(_ message:String,_ level:LogLevel) {
		log(message,[String](),level)
	}
	
	public func log(_ message:String,tags:[String]=[String](),level:LogLevel = .debug) {
		log(message,tags,level)
	}
	
	public func log(_ message:String,_ tags:[String],_ level:LogLevel) {
		let entry=LogEntry(tags: tags, level: level, message: message, timestamp: Date())
		entries.append(LogEntry(tags: tags, level: level, message: message, timestamp: Date()))
		if consoleFilter(entry) {
			print(LogEntry.toString(entry,consoleLineLength))
		}
		onLogActions.forEach { $0(entry) }
	}
	
	
}

