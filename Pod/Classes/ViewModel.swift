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

public enum Either<T1,T2>
{
	case First(T1)
	case Second(T2)
}

public protocol BaseViewModel {
	typealias Cell:UIView
	var cellNib:Either<UINib,UIView.Type>?  {get}
	var viewForEmptyList:UIView? {get}
	var viewForEmptySearch:UIView? {get}
}


public protocol ViewModel:BaseViewModel {
	typealias Data
	func cellFactory(index:Int,item:Data,cell:Cell)
}

public protocol SectionViewModel:BaseViewModel {
	typealias Section
	typealias Element
	func cellFactory(index:Int,item:Section,elements:[Element],cell:Cell)
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
	func cellSize(index:Int,item:Data,maxWidth:CGFloat)->CGSize
}

public enum EmptyBehaviour {
	case None
	case LabelWithString(s:String)
	case CustomView(v:UIView)
	func getView()->UIView?
	{
		switch self {
		case .None:
			return nil
		case .LabelWithString(let s):
			let lab=UILabel()
			lab.text=NSLocalizedString(s, comment: "")
			lab.textAlignment = .Center
			return lab
		case .CustomView(let v):
			return v
		}
	}

}
public class BaseConcreteViewModel<_Data,_Cell:UIView,_ClosureType>
{
	public typealias Cell=_Cell
	public typealias ClosureType=_ClosureType
	public var cellNib:Either<UINib,UIView.Type>?
	
	public var emptyBehaviour=EmptyBehaviour.LabelWithString(s: "La lista è vuota")
	public var viewForEmptyList:UIView? { return emptyBehaviour.getView() }
	
	public var emptySearchBehaviour=EmptyBehaviour.LabelWithString(s: "Nessun elemento corrisponde alla ricerca")
	public var viewForEmptySearch:UIView? { return emptySearchBehaviour.getView() }
	
	public typealias Data=_Data
		var cellFactoryClosure:ClosureType
	public init(cellName:String,cellFactory:ClosureType) {
		self.cellFactoryClosure=cellFactory
		cellNib = .First(UINib(nibName: cellName, bundle: nil))
	}
	public init(cellFactory:ClosureType) {
		self.cellFactoryClosure=cellFactory
		cellNib = Either.Second(Cell.self)
	}

}
public class ConcreteViewModel<Data,Cell:UITableViewCell>:BaseConcreteViewModel<Data,Cell,(index:Int,item:Data,cell:Cell)->Void>,ViewModel
{
	public override init(cellName:String,cellFactory:ClosureType) {
		super.init(cellName:cellName,cellFactory:cellFactory)
	}
	public override init(cellFactory:ClosureType) {
		super.init(cellFactory:cellFactory)
	}
	public func cellFactory(index: Int, item: Data, cell: Cell) {
		self.cellFactoryClosure(index: index, item: item, cell: cell)
	}
}

public class ConcreteCollectionViewModel<Data,Cell:UICollectionViewCell>:BaseConcreteViewModel<Data,Cell,(index:Int,item:Data,cell:Cell)->Void>,CollectionViewModel
{
	public override init(cellName:String,cellFactory:ClosureType) {
		cellForSizeCalculations=UINib(nibName: cellName, bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! Cell
		super.init(cellName:cellName,cellFactory:cellFactory)
	}
	public override init(cellFactory:ClosureType) {
		cellForSizeCalculations=Cell()
		super.init(cellFactory:cellFactory)
	}
	public func cellFactory(index: Int, item: Data, cell: Cell) {
		self.cellFactoryClosure(index: index, item: item, cell: cell)
	}
	public class var columns: UInt {return 1}
	public class var spacings:CellSpacings {
		return CellSpacings(horizontalBorder: 8,
		                    horizontalSpacing: 8,
		                    verticalBorder: 8,
		                    verticalSpacing: 8)}
	private let cellForSizeCalculations:Cell
	public func cellSize(index: Int, item: Data, maxWidth: CGFloat)->CGSize {
		let cell=cellForSizeCalculations
		cellFactory(index, item: item, cell: cell)
		return cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
	}
	
}
public class ConcreteSectionViewModel<Section,Element,Cell:UIView>:BaseConcreteViewModel<Section,Cell,(index:Int,item:Section,elements:[Element],cell:Cell)->Void>,SectionViewModel
{
	
	public override init(cellName:String,cellFactory:ClosureType) {
		super.init(cellName:cellName,cellFactory:cellFactory)
	}
	public override init(cellFactory:ClosureType) {
		super.init(cellFactory:cellFactory)
	}
	public func cellFactory(index:Int,item:Section,elements:[Element],cell:Cell) {
		self.cellFactoryClosure(index:index, item:item, elements:elements, cell:cell)
	}
}

public protocol WithApi {
	static func api(viewForActivityIndicator:UIView?,params:[String:AnyObject]?)->Observable<[Self]>
}
public protocol ApiResolver {
	associatedtype DataType
	func apiOrSource(source:Observable<[DataType]>?,viewForActivityIndicator: UIView?, params: [String : AnyObject]?) -> Observable<[DataType]>
	var typeHasApi:Bool {get}
	
}

//public extension ApiResolver where DataType:WithApi {
//	func apiOrSource(source:Observable<[DataType]>?,viewForActivityIndicator: UIView?, params: [String : AnyObject]?) -> Observable<[DataType]>
//	{
//		print("ApiResolver where DataType:WithApi")
//		if let source=source {
//			return source.shareReplayLatestWhileConnected()
//		} else {
//			return DataType.api(viewForActivityIndicator, params: params).subscribeOn(backgroundScheduler)
//				.map {$0}
//				.shareReplayLatestWhileConnected()
//				.observeOn(MainScheduler.instance)
//		}
//	}
//	var typeHasApi:Bool {return true}
//}
//
//public extension ApiResolver {
//	func apiOrSource(source:Observable<[DataType]>?,viewForActivityIndicator: UIView?, params: [String : AnyObject]?) -> Observable<[DataType]> {
//		print("ApiResolver")
//		if let source=source {
//			return source.shareReplayLatestWhileConnected()
////		} else if DataType.self is WithApi {
////			return (DataType.self as! WithApi).api(viewForActivityIndicator, params: params).subscribeOn(backgroundScheduler)
////				.map {$0}
////				.shareReplayLatestWhileConnected()
////				.observeOn(MainScheduler.instance)
//		} else {
//			fatalError("no api to extract data from, so you must provide a source")
//		}
//	}
//	
//	var typeHasApi:Bool {return false}
//}
public protocol DataExtractor {
	associatedtype DataType
	func data()->Observable<[DataType]>
}

public class DataExtractorBase<_DataType>:DataExtractor{
	public typealias DataType=_DataType
	var viewForActivityIndicator:UIView?
	public func data()->Observable<[DataType]> {fatalError("Base class, don't use me")}
}

public class StaticExtractor<_DataType>:DataExtractorBase<_DataType> {
	let source:Observable<[DataType]>
	
	public init(source:Observable<[_DataType]>){
		self.source=source
	}
	public override func data()->Observable<[DataType]>
	{
		return source.shareReplayLatestWhileConnected()
	}
}

public class ApiExtractor<_DataType where _DataType:WithApi>:DataExtractorBase<_DataType> {
	let apiParams:[String:AnyObject]?
	
	public init(apiParams: [String : AnyObject]?=nil)
	{
		self.apiParams=apiParams
	}
	
	public override func data()->Observable<[DataType]>
	{
		return  DataType.api(viewForActivityIndicator, params: apiParams)
			.subscribeOn(backgroundScheduler)
			.map {$0}
			.shareReplayLatestWhileConnected()
			.observeOn(MainScheduler.instance)
	}
}

public protocol Cached {
	static func invalidateCache()
}
public protocol WithCachedApi:WithApi,Cached {
}

