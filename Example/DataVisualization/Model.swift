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
import DataVisualization

struct Worker: Visualizable,WithApi
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
	static func api(viewForActivityIndicator: UIView?) -> Observable<[Worker]> {
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

struct Department:Visualizable {
	static func defaultViewModel() -> ViewModel {
		return ConcreteViewModel<Department,TitleHeader>(cellName: "TitleHeader") { (index, item, cell) -> Void in
			cell.title.text=item.name
		}
	}
	
	let id:UInt
	let name:String
}

func +<T>(array:[T],element:T)->[T]
{
	var copy=array
	copy.append(element)
	return copy
}

struct WorkerSectioner:Sectioner
{
	typealias Data=Worker
	typealias Section=Department
	typealias SectionAndData=(Section,[Data])
	var _sections=Variable([SectionAndData]())
	var sections:Observable<[SectionAndData]> { return _sections.asObservable() }
	let disposeBag=DisposeBag()
	init() {
		Data.api(nil).subscribeNext { (w:[Worker]) -> Void in
			self._sections.value=w
				.map{ $0.departmentId }
				.reduce([]) { (deps:[UInt], dep) in
					deps.contains(dep) ? deps : deps+dep
				}.map{ dep in
					(Department(id: dep, name: "dep n°\(dep)"),
					w.filter{ $0.departmentId==dep })
			}
		}.addDisposableTo(disposeBag)
	}
}
