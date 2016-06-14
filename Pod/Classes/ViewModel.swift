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
public class ConcreteViewModel<Data,Cell:UIView>:BaseConcreteViewModel<Data,Cell,(index:Int,item:Data,cell:Cell)->Void>,ViewModel
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
	static func api(viewForActivityIndicator:UIView?)->Observable<[Self]>
}
public protocol Cached {
	static func invalidateCache()
}
public protocol WithCachedApi:WithApi,Cached {
}

