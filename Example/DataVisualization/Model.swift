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


class WorkerViewModel:ViewModel
{
	typealias Data=Worker
	typealias Cell=TitleCell
	static let cellNib=UINib(nibName: "TitleCell", bundle: nil)
	func cellFactory(index: Int, item: Data, cell: Cell) {
		cell.title.text=item.name
	}
}

struct Worker: Visualizable
{
	typealias AViewModel=WorkerViewModel
	static func defaultViewModel() -> AViewModel {
		return WorkerViewModel()
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

