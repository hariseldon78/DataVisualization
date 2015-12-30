//
//  TableView.swift
//  DataVisualization
//
//  Created by Roberto Previdi on 28/12/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol Disposer {
	var disposeBag:DisposeBag {get}
}
protocol AutoSingleLevelTableView:Disposer {
	typealias Data:Visualizable,WithApi
	
	var viewModel:ViewModel {get}
	var data:Observable<[Data]> {get}
	func setupTableView(tableView:UITableView)
}

class AutoSingleLevelTableViewManager<DataType where DataType:Visualizable,DataType:WithApi>:AutoSingleLevelTableView
{
	typealias Data=DataType
	let data=Data.api()
	let disposeBag=DisposeBag()
	var viewModel=Data.defaultViewModel()

	func setupTableView(tableView:UITableView)
	{
		guard let nib=viewModel.cellNib else {
			fatalError("No cellNib defined: are you using ConcreteViewModel properly?")
		}
		
		switch nib
		{
		case .First(let nib):
			tableView.registerNib(nib, forCellReuseIdentifier: "cell")
		case .Second(let clazz):
			tableView.registerClass(clazz, forCellReuseIdentifier: "cell")
		}
		data
			.bindTo(tableView.rx_itemsWithCellIdentifier("cell")) {
				(index,item,cell)->Void in
				self.viewModel.cellFactory(index,item: item,cell: cell)
			}
			.addDisposableTo(self.disposeBag)
	}
}