//
//  SectionedTableView.swift
//  DataVisualization
//
//  Created by Roberto Previdi on 28/12/15.
//  Copyright © 2015 CocoaPods. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol Sectioner
{
	init()
}
//class Sectioner<Data:Visualizable,Section:Visualizable>
//{
//	required init(){}
//}

protocol AutoSectionedTableView:Disposer {
	typealias Data:Visualizable
	typealias Section:Visualizable
	typealias SectionerType:Sectioner
	var dataViewModel:ViewModel {get}
	var sectionViewModel:ViewModel {get}
	
	func setupTableView(tableView:UITableView)
	var sectioner:SectionerType {get}
}

class AutoSectionedTableViewManager<
	DataType:Visualizable,
	SectionType:Visualizable,
	_SectionerType:Sectioner
	>:AutoSectionedTableView
{
	@IBOutlet weak var tableView: UITableView!
	let disposeBag=DisposeBag()
	typealias Data=DataType
	typealias Section=SectionType
	typealias SectionerType=_SectionerType
	
	typealias RxSectionModel=SectionModel<Section,Data>
	let dataSource=RxTableViewSectionedReloadDataSource<RxSectionModel>()
	var sections=Variable([RxSectionModel]())
	
	var dataViewModel=Data.defaultViewModel()
	var sectionViewModel=Section.defaultViewModel()
	var sectioner=SectionerType()
	
	func setupTableView(tableView:UITableView)
	{
		guard let dataNib=dataViewModel.cellNib,
			sectionNib=sectionViewModel.cellNib
		else {fatalError("No cellNib defined: are you using ConcreteViewModel properly?")}
		tableView.registerNib(dataNib, forCellReuseIdentifier: "cell")
		tableView.registerNib(sectionNib, forHeaderFooterViewReuseIdentifier: "section")
//		data.subscribe
		
//				.bindTo(tableView.rx_itemsWithCellIdentifier("cell")) {
//					(index,item,cell)->Void in
//					self.viewModel().cellFactory(index,item: item,cell: cell)
//				}
//				.addDisposableTo(self.disposeBag)
		
	}
	func tableView(tableView: UITableView,
		viewForHeaderInSection section: Int) -> UIView?
	{
		let hv:UIView?=tableView.dequeueReusableCellWithIdentifier("section")
		return nil
	}
}

