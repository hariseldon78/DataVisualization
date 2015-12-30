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

enum Either<T1,T2>
{
	case First(T1)
	case Second(T2)
}

class ViewModel {
	var cellNib:Either<UINib,UIView.Type>?
	func cellFactory(index:Int,item:Any,cell:UIView)->Void {}
}

class ConcreteViewModel<Data,Cell:UIView>:ViewModel
{
	var cellFactoryClosure:(index:Int,item:Data,cell:Cell)->Void
	init(cellName:String,cellFactory:(index:Int,item:Data,cell:Cell)->Void) {
		self.cellFactoryClosure=cellFactory
		super.init()
		cellNib = .First(UINib(nibName: cellName, bundle: nil))
	}
	init(cellFactory:(index:Int,item:Data,cell:Cell)->Void) {
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
}

protocol Visualizable {
	static func defaultViewModel()->ViewModel
}
protocol WithApi {
	static func api()->Observable<[Self]>
}
