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

public class ViewModel {
	public var cellNib:Either<UINib,UIView.Type>?
	func cellFactory(index:Int,item:Any,cell:UIView)->Void {}
	public var viewForEmptyList:UIView? {return nil}
	public var viewForEmptySearch:UIView? {return nil}
}

public class ConcreteViewModel<Data,Cell:UIView>:ViewModel
{
	var cellFactoryClosure:(index:Int,item:Data,cell:Cell)->Void
	public init(cellName:String,cellFactory:(index:Int,item:Data,cell:Cell)->Void) {
		self.cellFactoryClosure=cellFactory
		super.init()
		cellNib = .First(UINib(nibName: cellName, bundle: nil))
	}
	public init(cellFactory:(index:Int,item:Data,cell:Cell)->Void) {
		self.cellFactoryClosure=cellFactory
		super.init()
		cellNib = Either.Second(Cell.self)
	}
	override func cellFactory(index: Int, item: Any, cell: UIView) {
		guard let item=item as? Data,
			cell=cell as? Cell
			else {fatalError("ViewModel used with wrong data type or cell")}
		self.cellFactoryClosure(index: index, item: item, cell: cell)
	}
	public override var viewForEmptyList:UIView? {
		let lab=UILabel()
		lab.text=NSLocalizedString("La lista è vuota", comment: "")
		lab.textAlignment = .Center
		return lab
	}
	public override var viewForEmptySearch:UIView? {
		let lab=UILabel()
		lab.text=NSLocalizedString("Nessun elemento corrisponde alla ricerca", comment: "")
		lab.textAlignment = .Center
		return lab
	}
	
}

public protocol Visualizable {
	static func defaultViewModel()->ViewModel
}
public protocol SectionVisualizable {
	static func defaultSectionViewModel()->ViewModel
}
public protocol WithApi {
	static func api(viewForActivityIndicator:UIView?)->Observable<[Self]>
}
public protocol WithCachedApi:WithApi {
	static func invalidateCache()
}

