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

public protocol ViewModel {
	typealias Data
	typealias Cell:UIView
	var cellNib:Either<UINib,UIView.Type>?  {get}
	func cellFactory(index:Int,item:Data,cell:Cell)->Void
	var viewForEmptyList:UIView? {get}
	var viewForEmptySearch:UIView? {get}
}


public class ConcreteViewModel<_Data,Cell:UIView>:ViewModel
{
	public typealias Data=_Data
	public var cellNib:Either<UINib,UIView.Type>?
	var cellFactoryClosure:(index:Int,item:Data,cell:Cell)->Void
	public init(cellName:String,cellFactory:(index:Int,item:Data,cell:Cell)->Void) {
		self.cellFactoryClosure=cellFactory
		cellNib = .First(UINib(nibName: cellName, bundle: nil))
	}
	public init(cellFactory:(index:Int,item:Data,cell:Cell)->Void) {
		self.cellFactoryClosure=cellFactory
		cellNib = Either.Second(Cell.self)
	}
	public func cellFactory(index: Int, item: Data, cell: Cell) {
		self.cellFactoryClosure(index: index, item: item, cell: cell)
	}
	public var viewForEmptyList:UIView? {
		let lab=UILabel()
		lab.text=NSLocalizedString("La lista è vuota", comment: "")
		lab.textAlignment = .Center
		return lab
	}
	public var viewForEmptySearch:UIView? {
		let lab=UILabel()
		lab.text=NSLocalizedString("Nessun elemento corrisponde alla ricerca", comment: "")
		lab.textAlignment = .Center
		return lab
	}
	
}

public protocol Visualizable {
	typealias ViewModelPAT:ViewModel
	static func defaultViewModel()->ViewModelPAT
}


public protocol SectionVisualizable {
	typealias ViewModelPAT:ViewModel
	static func defaultSectionViewModel()->ViewModelPAT
}
public protocol WithApi {
	static func api(viewForActivityIndicator:UIView?)->Observable<[Self]>
}
public protocol Cached {
	static func invalidateCache()
}
public protocol WithCachedApi:WithApi,Cached {
}

