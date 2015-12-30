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
	typealias Data
	typealias Section
	var sections:Observable<[(Section,[Data])]> {get}
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
	_SectionerType:Sectioner where _SectionerType.Data==DataType,_SectionerType.Section==SectionType
	>:NSObject,AutoSectionedTableView,UITableViewDelegate
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
		
		switch dataNib
		{
		case .First(let nib):
			tableView.registerNib(nib, forCellReuseIdentifier: "cell")
		case .Second(let clazz):
			tableView.registerClass(clazz, forCellReuseIdentifier: "cell")
		}
			
		switch sectionNib
		{
		case .First(let nib):
			tableView.registerNib(nib, forHeaderFooterViewReuseIdentifier: "section")
		case .Second(let clazz):
			tableView.registerClass(clazz, forHeaderFooterViewReuseIdentifier: "section")
		}
		tableView.delegate=self
		sectioner.sections.subscribeNext { (secs:[(Section, [Data])]) -> Void in
			self.sections.value=secs.map{ (s,d) in
				RxSectionModel(model: s, items: d)
			}
		}.addDisposableTo(disposeBag)
		dataSource.cellFactory={
			(tableView,indexPath,item:Data) in
			guard let cell=tableView.dequeueReusableCellWithIdentifier("cell")
				else {fatalError("why no cell?")}
			self.dataViewModel.cellFactory(indexPath.row, item: item, cell: cell)
			return cell
		}
		
		sections.bindTo(tableView.rx_itemsWithDataSource(dataSource))
			.addDisposableTo(disposeBag)
	
	}
	func tableView(tableView: UITableView,
		viewForHeaderInSection section: Int) -> UIView?
	{
		guard let hv=tableView.dequeueReusableHeaderFooterViewWithIdentifier("section")
			else {fatalError("why no section cell?")}
		let s=sections.value[section].model
		sectionViewModel.cellFactory(section, item: s, cell: hv)
		return nil
	}
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		guard let hv=tableView.dequeueReusableHeaderFooterViewWithIdentifier("section")
			else {fatalError("why no section cell?")}
		return hv.bounds.height
	}
}

