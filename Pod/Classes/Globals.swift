//
//  DataVisualization.swift
//  Pods
//
//  Created by Roberto Previdi on 11/07/16.
//
//

import Foundation
func originalFatalError(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> Never
{
	fatalError(message,file:file,line:line)
}
open class DataVisualization {
	static open var nonFatalErrorMessageHandler:((String)->())={ e  in
		originalFatalError(e)
	}
	static open var nonFatalErrorHandler:((NSError)->())={ e in
		nonFatalErrorMessageHandler(e.localizedDescription)
	}
	
	static open var fatalErrorMessageHandler:((String)->())={ e  in
		originalFatalError(e)
	}
	static open var fatalErrorHandler:((NSError)->())={ e in
		fatalErrorMessageHandler(e.localizedDescription)
	}
	
	open class func nonFatalError(_ error:NSError)
	{
		nonFatalErrorHandler(error)
	}
	
	open class func nonFatalError(_ string:String="")
	{
		nonFatalErrorMessageHandler(string)
	}
	
	open class func fatalError(_ error:NSError) -> Never
	{
		fatalErrorHandler(error)
		exit(1)
	}
	
	open class func fatalError(_ string:String="") -> Never
	{
		fatalErrorMessageHandler(string)
		exit(1)
	}
	
}

