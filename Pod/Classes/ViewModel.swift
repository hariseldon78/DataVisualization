//
//  ViewModel.swift
//  DataVisualization
//
//  Created by Roberto Previdi on 28/12/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public enum ProgressType {
	case indeterminate
}

public struct ProgressContext {
	public let viewController:UIViewController?
	public let view:UIView?
	public let type:ProgressType
	public init(viewController:UIViewController?, view:UIView?, type:ProgressType) {
		self.viewController=viewController
		self.view=view
		self.type=type
	}
}

public enum Either<T1,T2>
{
	case first(T1)
	case second(T2)
}

public protocol BaseViewModel {
	associatedtype Cell:UIView
	var cellNib:Either<UINib,UIView.Type>?  {get}
	var viewForEmptyList:UIView? {get}
	var viewForEmptySearch:UIView? {get}
}


public protocol ViewModel:BaseViewModel {
	associatedtype Data
	func cellFactory(_ index:Int,item:Data,cell:Cell)
}

public protocol SectionViewModel:BaseViewModel {
	associatedtype Section
	associatedtype Element
	func cellFactory(_ index:Int,item:Section,elements:[Element],cell:Cell)
}

public struct CellSpacings {
	var horizontalBorder:CGFloat
	var horizontalSpacing:CGFloat
	var verticalBorder:CGFloat
	var verticalSpacing:CGFloat
}

public protocol CollectionViewModel:ViewModel {
	static var columns:UInt {get}
	static var spacings:CellSpacings {get}
	func cellSize(_ index:Int,item:Data,maxWidth:CGFloat)->CGSize
	var cellResizeEvents:PublishSubject<Void> {get}
}

public enum EmptyBehaviour {
	case none
	case labelWithString(s:String)
	case customView(v:UIView)
	func getView()->UIView?
	{
		switch self {
		case .none:
			return nil
		case .labelWithString(let s):
			let lab=UILabel()
			lab.text=NSLocalizedString(s, comment: "")
			lab.textAlignment = .center
			return lab
		case .customView(let v):
			return v
		}
	}

}
open class BaseConcreteViewModel<_Data,_Cell:UIView,_ClosureType>
{
	public typealias Cell=_Cell
	public typealias ClosureType=_ClosureType
	open var cellNib:Either<UINib,UIView.Type>?
	
	open var emptyBehaviour=EmptyBehaviour.labelWithString(s: "La lista è vuota")
	open var viewForEmptyList:UIView? { return emptyBehaviour.getView() }
	
	open var emptySearchBehaviour=EmptyBehaviour.labelWithString(s: "Nessun elemento corrisponde alla ricerca")
	open var viewForEmptySearch:UIView? { return emptySearchBehaviour.getView() }
	
	public typealias Data=_Data
		var cellFactoryClosure:ClosureType
	public init(cellName:String,cellFactory:ClosureType) {
		self.cellFactoryClosure=cellFactory
		cellNib = .first(UINib(nibName: cellName, bundle: nil))
	}
	public init(cellFactory:ClosureType) {
		self.cellFactoryClosure=cellFactory
		cellNib = Either.second(Cell.self)
	}

}
open class ConcreteViewModel<Data,Cell:UITableViewCell>:BaseConcreteViewModel<Data,Cell,(_ index:Int,_ item:Data,_ cell:Cell)->Void>,ViewModel
{
	public override init(cellName:String,cellFactory:@escaping ClosureType) {
		super.init(cellName:cellName,cellFactory:cellFactory)
	}
	public override init(cellFactory:@escaping ClosureType) {
		super.init(cellFactory:cellFactory)
	}
	open func cellFactory(_ index: Int, item: Data, cell: Cell) {
		self.cellFactoryClosure(index, item, cell)
	}
}
public typealias CollectionClosureType<Cell,Data>=(_ index:Int,_ item:Data,_ cell:Cell,_ resizeEventsSink:PublishSubject<Void>)->Void
open class ConcreteCollectionViewModel<Data,Cell:UICollectionViewCell>:BaseConcreteViewModel<Data,Cell,CollectionClosureType<Cell,Data>>,CollectionViewModel
{
	public override init(cellName: String, cellFactory: @escaping ClosureType) {
		cellForSizeCalculations=UINib(nibName: cellName, bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! Cell
		super.init(cellName:cellName,cellFactory:cellFactory)
	}

	public override init(cellFactory: @escaping ClosureType) {
		cellForSizeCalculations=Cell()
		super.init(cellFactory:cellFactory)
	}
	open func cellFactory(_ index: Int, item: Data, cell: Cell) {
		self.cellFactoryClosure(index, item, cell, cellResizeEvents)
	}
	open class var columns: UInt {return 1}
	open class var spacings:CellSpacings {
		return CellSpacings(horizontalBorder: 8,
		                    horizontalSpacing: 8,
		                    verticalBorder: 8,
		                    verticalSpacing: 8)}
	fileprivate let cellForSizeCalculations:Cell
	open func cellSize(_ index: Int, item: Data, maxWidth: CGFloat)->CGSize {
		let cell=cellForSizeCalculations
		cell.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[cell(maxWidth)]", options: NSLayoutFormatOptions(), metrics: ["maxWidth":maxWidth], views: ["cell":cell.contentView]))
		cellFactory(index, item: item, cell: cell)
		return cell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
	}
	open let cellResizeEvents=PublishSubject<Void>()
	
}
open class ConcreteSectionViewModel<Section,Element,Cell:UIView>:BaseConcreteViewModel<Section,Cell,(_ index:Int,_ item:Section,_ elements:[Element],_ cell:Cell)->Void>,SectionViewModel
{
	
	public override init(cellName:String,cellFactory:@escaping ClosureType) {
		super.init(cellName:cellName,cellFactory:cellFactory)
	}
	public override init(cellFactory:@escaping ClosureType) {
		super.init(cellFactory:cellFactory)
	}
	open func cellFactory(_ index:Int,item:Section,elements:[Element],cell:Cell) {
		self.cellFactoryClosure(index, item, elements, cell)
	}
}

public protocol WithApi {
	static func api(_ progressContext:ProgressContext?,params:[String:Any]?)->Observable<[Self]>
}
public protocol ApiResolver {
	associatedtype DataType
	func apiOrSource(_ source:Observable<[DataType]>?,progressContext:ProgressContext?, params: [String : AnyObject]?) -> Observable<[DataType]>
	var typeHasApi:Bool {get}
	
}

public protocol DataExtractor {
	associatedtype DataType
	func data()->Observable<[DataType]>
	func refresh()
}

open class DataExtractorBase<_DataType>:DataExtractor{
	public typealias DataType=_DataType
	public var progressContext:ProgressContext?
	final public func data()->Observable<[DataType]> {
		return refresher.output.shareReplayLatestWhileConnected()
	}
	var refresher:Refresher<[DataType]>!=nil // must be inited by subclasses
	init(source:@escaping ()->Observable<[DataType]>,progressContext:ProgressContext?=nil) {
		self.progressContext=progressContext
		refresher=Refresher(source: source)
		refresh()
	}
	init(progressContext:ProgressContext?=nil) {
		self.progressContext=progressContext
	}
	final public func refresh() {
		refresher.refresh()
	}
}

open class StaticExtractor<_DataType>:DataExtractorBase<_DataType> {
	public init(source:@autoclosure @escaping ()->Observable<[_DataType]>){
		super.init(source:source)
	}
}

open class ApiExtractor<_DataType>:DataExtractorBase<_DataType> where _DataType:WithApi {
//	let apiParams:[String:Any]?
	
	public init(apiParams: [String : Any]?=nil,progressContext:ProgressContext?=nil)
	{
		super.init(progressContext:progressContext)
		refresher=Refresher {
			DataType.api(super.progressContext, params: apiParams)
				.subscribeOn(backgroundScheduler)
				.map {$0}
				.shareReplayLatestWhileConnected()
				.observeOn(MainScheduler.instance)
		}
		refresh()
	}
}

public protocol Cached {
	static func invalidateCache()
}
public protocol WithCachedApi:WithApi,Cached {
}

