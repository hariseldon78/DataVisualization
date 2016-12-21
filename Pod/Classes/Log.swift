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
	func toString()->String
	{
		switch self {
		case .error:
			return "error"
		case .info:
			return "info"
		case .debug:
			return "debug"
		case .verbose:
			return "verbose"
		}
	}
	func atLeast(_ level:LogLevel)->Bool
	{
		return rawValue>=level.rawValue
	}
	func ifAtLeast(_ level:LogLevel,closure:()->())
	{
		if atLeast(level)
		{
			closure()
		}
	}

}

extension String {
	func toField(_ length:Int,separator:String=" ")->String {
		return padding(toLength: length-1, withPad: " ", startingAt: 0)+separator
	}
	
	func toMultilineField(_ length:Int,separator:String=" ")->MultilineString
	{
		return MultilineSingleString(string:self,length:length,separator:separator)
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
struct MultilineSingleString:MultilineString {
	let source:String
	let length:Int
	let separator:String
	init(string:String,length:Int,separator:String=" "){
		source=string
		self.length=length
		self.separator=separator
	}
	
	func toLines()->[String] {
		var cursor=source.startIndex
		var ret=[String]()
		repeat {
			if let rangeEnd=source.index(cursor,offsetBy:length-1,limitedBy:source.endIndex) {
				ret.append(source.substring(with: cursor..<rangeEnd)+separator)
				cursor=rangeEnd
			} else {
				ret.append(source.substring(from: cursor).toField(length,separator:separator))
				return ret
			}
		} while true
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
		let multilineString=e.level.toString().toMultilineField(8) +
			"\(tags)".toMultilineField(10) +
			e.message.toMultilineField(lineLength-18)
		return multilineString.toString()
	}
}

public class LogManager {
	public init(){}
	public var entries=[LogEntry]()
	public var consoleFilter:(LogEntry)->Bool = {_ in return true}
	public var consoleLineLength=140
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
	}
	
	
}

