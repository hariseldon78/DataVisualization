//
//  Model.swift
//  DataVisualization
//
//  Created by Roberto Previdi on 27/12/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct Worker: Visualizable
{
	static func defaultViewModel() -> ViewModel {
		return ConcreteViewModel<Worker,TitleCell>(cellName: "TitleCell") { (index, item, cell) -> Void in
			cell.title.text=item.name
		}
	}
	
	let id:UInt
	let name:String
	let salary:Double
	let departmentId:UInt
	static func api()->Observable<[Worker]>
	{
		return [
			[
				"id":0,
				"name":"Gianni",
				"salary":1000.0,
				"departmentId":0
			],
			[
				"id":1,
				"name":"Luigi",
				"salary":1200.0,
				"departmentId":0
			],
			[
				"id":2,
				"name":"Arturo",
				"salary":1800.0,
				"departmentId":1
			],
			[
				"id":3,
				"name":"Gianfranco",
				"salary":1100.0,
				"departmentId":0
			]
			].map{ w->Worker in
				guard let id:UInt=w["id"] as? UInt,
					name:String=w["name"] as? String,
					salary:Double=w["salary"] as? Double,
					dep:UInt=w["departmentId"] as? UInt
					else {fatalError()}
			
				return Worker(id: id , name: name, salary: salary, departmentId: dep)
			}.toObservable().toArray()
	}
	
}

struct Department {
	let id:UInt
	let name:String
}

