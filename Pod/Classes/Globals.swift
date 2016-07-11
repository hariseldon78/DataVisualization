//
//  DataVisualization.swift
//  Pods
//
//  Created by Roberto Previdi on 11/07/16.
//
//

import Foundation

public class DataVisualization {
	static public var nonFatalErrorMessageHandler:((String)->())={ e  in
		fatalError(e)
	}
	static public var nonFatalErrorHandler:((NSError)->())={ e in
		nonFatalErrorMessageHandler(e.localizedDescription)
	}
	
	static public var fatalErrorMessageHandler:((String)->())={ e  in
		fatalError(e)
	}
	static public var fatalErrorHandler:((NSError)->())={ e in
		fatalErrorMessageHandler(e.localizedDescription)
	}
	
	@noreturn public class func nonFatalError(error:NSError)
	{
		nonFatalErrorHandler(error)
		exit(1)
	}
	
	@noreturn public class func nonFatalError(string:String="")
	{
		nonFatalErrorMessageHandler(string)
		exit(1)
	}
	
	@noreturn public class func fatalError(error:NSError)
	{
		fatalErrorHandler(error)
		exit(1)
	}
	
	@noreturn public class func fatalError(string:String="")
	{
		fatalErrorMessageHandler(string)
		exit(1)
	}
	
}

