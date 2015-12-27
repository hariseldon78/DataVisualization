//
//  DataVisualization.swift
//  DataVisualization
//
//  Created by Roberto Previdi on 27/12/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol ViewModel {
	typealias Data
	typealias Cell:UITableViewCell
	static var cellNib:UINib {get}
	func cellFactory(index:Int,item:Data,cell:Cell)->Void

}

protocol Visualizable {
	typealias AViewModel:ViewModel
	static func defaultViewModel()->AViewModel
}

protocol AutoSingleLevelTableView {
	typealias Data:Visualizable
	func viewModel()->Data.AViewModel
	var disposeBag:DisposeBag {get}
	func data()->Observable<[Data]>
	func setupTableView(tableView:UITableView)
}
extension AutoSingleLevelTableView {
	func viewModel()->Data.AViewModel
	{
		return Data.defaultViewModel()
	}
	func setupTableView(tableView:UITableView)
	{
		
		tableView.registerNib(Data.AViewModel.cellNib, forCellReuseIdentifier: "cell")
		data()
			.bindTo(tableView.rx_itemsWithCellIdentifier("cell")) {
				(index:Int,item,cell)->Void in
				guard let item=item as? Data.AViewModel.Data,
					cell=cell as? Data.AViewModel.Cell
					else
				{fatalError()}
				self.viewModel().cellFactory(index,item: item,cell: cell)
			}
			.addDisposableTo(disposeBag)
	}
}

