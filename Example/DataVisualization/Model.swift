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

var cached=true

extension Array{
	mutating func maybeAppend(_ e:Element,p:Double=0.5)
	{
		if Double(arc4random()%100)<p*100.0
		{
			append(e)
		}
	}
}
struct Worker: WithCachedApi
{
	typealias DefaultViewModel=ConcreteViewModel<Worker,TitleCell>
	static func defaultViewModel() -> DefaultViewModel {
		return DefaultViewModel(cellName: "TitleCell") { (index, item, cell) -> Void in
			cell.title.text=item.name
		}
	}
	
	typealias DefaultCollectionViewModel=ConcreteCollectionViewModel<Worker,CollectionTitleCell>
	static func defaultCollectionViewModel() -> DefaultCollectionViewModel {
		return DefaultCollectionViewModel(cellName: "CollectionTitleCell") { (index, item, cell, resizeSink) -> Void in
			cell.title.text=item.name
			cell.indexPath=IndexPath(item: index,section: 0)
			cell.resizeSink=resizeSink
			var s=String()
			let max=Int(item.salary/100)*2
			for _ in 0..<max {
				s+=item.name
				s+=" "
			}
			cell.details.text=s
		}
	}
	
	let id:UInt
	let name:String
	let salary:Double
	let departmentId:UInt
	static func api(_ viewForActivityIndicator: UIView?,params:[String:Any]?=nil) -> Observable<[Worker]> {
		var array=[
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
		]
		
		if !cached {
			array.append([
				"id":4,
				"name":"Carletta",
				"salary":1700.0,
				"departmentId":1
				])
		}
		array.maybeAppend([
			"id":5,
			"name":"Adele",
			"salary":1130.0,
			"departmentId":0
			])
		array.maybeAppend([
			"id":6,
			"name":"Berta",
			"salary":1130.0,
			"departmentId":0
			])
		array.maybeAppend([
			"id":7,
			"name":"Carla",
			"salary":1130.0,
			"departmentId":0
			])
		array.maybeAppend([
			"id":8,
			"name":"Diana",
			"salary":1130.0,
			"departmentId":0
			])
		array.maybeAppend([
			"id":9,
			"name":"Emma",
			"salary":1130.0,
			"departmentId":0
			])
		array.maybeAppend([
			"id":10,
			"name":"Fausta",
			"salary":1130.0,
			"departmentId":0
			])
		array.maybeAppend([
			"id":11,
			"name":"Ilaria",
			"salary":1130.0,
			"departmentId":0
			])

		if let params=params,
			let name=params["name"] as? String,
			let salary=params["salary"] as? Double,
			let department=params["department"] as? Int {
				array.append([
					"id":12,
					"name":name,
					"salary":salary,
					"departmentId":department
				])
		}
		
		
		return Observable.create({ (observer) -> Disposable in
			assert(Thread.current != Thread.main)
			Thread.sleep(forTimeInterval: 2)
			let data=array
				.map{ w->Worker in
					guard let id:Int=w["id"] as? Int,
						let name:String=w["name"] as? String,
						let salary:Double=w["salary"] as? Double,
						let dep:Int=w["departmentId"] as? Int
						else {fatalError()}

					return Worker(id: UInt(id) , name: name, salary: salary, departmentId: UInt(dep))
			}
			observer.onNext(data)
			observer.onCompleted()
			return Disposables.create {}
		})
	}
	static func invalidateCache() {
		cached=false
	}
}

struct Department:CollapsableSection {
	var collapseState:SectionCollapseState = .expanded
	var elementsCount:Int=0
	typealias DefaultSectionViewModel=ConcreteSectionViewModel<Department,Worker,TitleHeader>
	static func defaultSectionViewModel() -> DefaultSectionViewModel {
		return DefaultSectionViewModel(cellName: "TitleHeader") {
			(index, item, elements, cell) -> Void in
			cell.title.text="\(item.collapseState.char) - \(item.name) - \(item.elementsCount) items"
		}
	}
	init(collapseState:SectionCollapseState, id: UInt, name: String)
	{
		self.collapseState=collapseState
		self.id=id
		self.name=name
	}
	let id:UInt
	let name:String
}
func ==(a:Department,b:Department)->Bool
{
	return (a.id == b.id)
}


func +<T>(array:[T],element:T)->[T]
{
	var copy=array
	copy.append(element)
	return copy
}

class WorkerSectioner:RefreshableSectioner<Department,Worker>,Cached
{
	var _viewForActivityIndicator=Variable<UIView?>(nil)
	
	override func _sections() -> Observable<[SectionAndData]> {
		// FIXME: this pattern is very wrong: it refetches data just to display the activity indicator in the correct place
		return _viewForActivityIndicator.asObservable()
			.observeOn(OperationQueueScheduler(operationQueue:OperationQueue()))
			.map{ (v) in
				Data.api(v)
			}
			.subscribeOn(OperationQueueScheduler(operationQueue:OperationQueue()))
			.flatMap { $0 }
			.map { (w:[Worker]) in
				let ret=w
					.map{ $0.departmentId }
					.reduce([]) { (deps:[UInt], dep) in
						deps.contains(dep) ? deps : deps+dep
					}.map{ dep in
						(Department(collapseState:.expanded, id: dep, name: "dep n°\(dep)"),
							w.filter{ $0.departmentId==dep })
				}
				return ret
		}
	}
	
	override var viewForActivityIndicator: UIView? {didSet{_viewForActivityIndicator.value=viewForActivityIndicator}}
	
//	func resubscribe() {
//		_refresher.value+=1
//	}
	static func invalidateCache() {
		Data.invalidateCache()
	}
}
