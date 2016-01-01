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

public protocol Disposer {
	var disposeBag:DisposeBag {get}
}
public protocol AutoSingleLevelTableView:Disposer {
	typealias Data:Visualizable,WithApi
	
	var viewModel:ViewModel {get}
	var data:Observable<[Data]> {get}
	func setupTableView(tableView:UITableView,vc:UIViewController)
}

public protocol DetailView {
	var detailManager:DetailManagerType {get set}
}
public protocol DetailManagerType
{
	var object:Any? {get set}
	func viewDidLoad()
}
public class DetailManager<Data>:DetailManagerType
{
	public init(){}
	let disposeBag=DisposeBag()
	var objObs:Variable<Data>!
	public var object:Any? {didSet{
		guard let w=object as? Data else {fatalError("wrong type passed to detailManager")}
		if objObs==nil { objObs=Variable(w) }
		else { objObs.value=w }
		}
	}
	public typealias Binder=(obj:Observable<Data>,disposeBag:DisposeBag)->()
	public var binder:Binder?
	public func viewDidLoad() {
		let obj=objObs.observeOn(MainScheduler.sharedInstance)
		binder?(obj:obj,disposeBag:disposeBag)
	}

}
public class AutoSingleLevelTableViewManager<DataType where DataType:Visualizable,DataType:WithApi>:AutoSingleLevelTableView
{
	public typealias Data=DataType
	public let data=Data.api()
	public let disposeBag=DisposeBag()
	public var viewModel=Data.defaultViewModel()
	var vc:UIViewController!

	var onClick:((row:Data)->())?=nil
	var clickedObj:Data?
	
	public init(){}
	public func setupTableView(tableView:UITableView,vc:UIViewController)
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
				if self.onClick != nil
				{
					cell.accessoryType=UITableViewCellAccessoryType.DisclosureIndicator
				}
			}
			.addDisposableTo(self.disposeBag)
		tableView
			.rx_modelSelected(Data.self)
			.subscribeNext { (obj) -> Void in
				self.clickedObj=obj
				self.onClick?(row: obj)
		}.addDisposableTo(disposeBag)
	}
	
	var detailSegue:String?=nil
	public func setupDetail(segue:String)
	{
		detailSegue=segue
		onClick={ row in
			self.vc.performSegueWithIdentifier(segue, sender: nil)
		}
	}
	public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		guard var dest=segue.destinationViewController as? DetailView,
			let identifier=segue.identifier,
			let detailSegue=detailSegue else {return}
		if identifier==detailSegue
		{
			dest.detailManager.object=clickedObj
		}
	}
	
}





