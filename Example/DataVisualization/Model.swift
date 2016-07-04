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
	mutating func maybeAppend(e:Element,p:Double=0.5)
	{
		if Double(random()%100)<p*100.0
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
		return DefaultCollectionViewModel(cellName: "CollectionTitleCell") { (index, item, cell) -> Void in
			cell.title.text=item.name
		}
	}
	
	let id:UInt
	let name:String
	let salary:Double
	let departmentId:UInt
	static func api(viewForActivityIndicator: UIView?) -> Observable<[Worker]> {
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

		
		return Observable.create({ (observer) -> Disposable in
			assert(NSThread.currentThread() != NSThread.mainThread())
			NSThread.sleepForTimeInterval(2)
			let data=array
				.map{ w->Worker in
					guard let id:UInt=w["id"] as? UInt,
						name:String=w["name"] as? String,
						salary:Double=w["salary"] as? Double,
						dep:UInt=w["departmentId"] as? UInt
						else {fatalError()}
					
					return Worker(id: id , name: name, salary: salary, departmentId: dep)
			}
			observer.onNext(data)
			observer.onCompleted()
			return AnonymousDisposable {}
		})
	}
	static func invalidateCache() {
		cached=false
	}
}

struct Department:CollapsableSection {
	var collapseState:SectionCollapseState = .Expanded
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

class WorkerSectioner:Sectioner,Cached
{
	typealias Data=Worker
	typealias Section=Department
	typealias SectionAndData=(Section,[Data])
	var _viewForActivityIndicator=Variable<UIView?>(nil)
	var _refresher=Variable(0)
	var sections:Observable<[SectionAndData]> {
		return Observable.combineLatest(_viewForActivityIndicator.asObservable(), _refresher.asObservable()){ $0.0 }
			.observeOn(OperationQueueScheduler(operationQueue:NSOperationQueue()))
			.map{ (v) in
				Data.api(v)
			}
			.subscribeOn(OperationQueueScheduler(operationQueue:NSOperationQueue()))
			.flatMap { $0 }
			.map { (w:[Worker]) in
				let ret=w
					.map{ $0.departmentId }
					.reduce([]) { (deps:[UInt], dep) in
						deps.contains(dep) ? deps : deps+dep
					}.map{ dep in
						(Department(collapseState:.Expanded, id: dep, name: "dep n°\(dep)"),
							w.filter{ $0.departmentId==dep })
				}
				return ret
		}
	}
	
	var viewForActivityIndicator: UIView? {didSet{_viewForActivityIndicator.value=viewForActivityIndicator}}
	
	func resubscribe() {
		_refresher.value+=1
	}
	static func invalidateCache() {
		Data.invalidateCache()
	}
}
