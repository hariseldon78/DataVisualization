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
	func setupTableView(tableView:UITableView,vc:UIViewController)
}

protocol DetailView {
	var detailManager:DetailManagerType {get set}
}
protocol DetailManagerType
{
	var object:Any? {get set}
	func viewDidLoad()
}
class DetailManager<Data>:DetailManagerType
{
	let disposeBag=DisposeBag()
	var objObs:Variable<Data>!
	var object:Any? {didSet{
		guard let w=object as? Data else {return}
		if objObs==nil { objObs=Variable(w) }
		else { objObs.value=w }
		}
	}
	typealias Binder=(obj:Observable<Data>,disposeBag:DisposeBag)->()
	var binder:Binder?
	func viewDidLoad() {
		let obj=objObs.observeOn(MainScheduler.sharedInstance)
		binder?(obj:obj,disposeBag:disposeBag)
	}

}
class AutoSingleLevelTableViewManager<DataType where DataType:Visualizable,DataType:WithApi>:AutoSingleLevelTableView
{
	typealias Data=DataType
	let data=Data.api()
	let disposeBag=DisposeBag()
	var viewModel=Data.defaultViewModel()
	var vc:UIViewController!

	var onClick:((row:Data)->())?=nil
	var clickedObj:Data?
	
	func setupTableView(tableView:UITableView,vc:UIViewController)
	{
		guard let nib=viewModel.cellNib else {
			fatalError("No cellNib defined: are you using ConcreteViewModel properly?")
		}
		
		self.vc=vc
		
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
		tableView
			.rx_modelSelected(Data.self)
			.subscribeNext { (obj) -> Void in
				self.clickedObj=obj
				self.onClick!(row: obj)
		}.addDisposableTo(disposeBag)
	}
	
	var detailSegue:String?=nil
	func setupDetail(segue:String)
	{
		detailSegue=segue
		onClick={ row in
			self.vc.performSegueWithIdentifier(segue, sender: nil)
		}
	}
	func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier==detailSegue
		{
			if var dest=segue.destinationViewController as? DetailView
			{
				dest.detailManager.object=clickedObj
			}
		}
	}
	
}





