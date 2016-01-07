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

public protocol ControllerWithTableView
{
	var tableView:UITableView! {get}
	var vc:UIViewController! {get}
}

public protocol AutoSingleLevelTableView:Disposer {
	typealias Data:Visualizable,WithApi
	
	var viewModel:ViewModel {get}
	var data:Observable<[Data]>! {get}
	func setupTableView(tableView:UITableView,vc:UIViewController)
}

// non dovrebbe essere pubblico
public protocol Searchable:class,ControllerWithTableView,Disposer
{
	var searchController:UISearchController! {get set}
	func setupSearchController()
}

public extension Searchable
{
	
	/// To be called in viewDidLoad
	func setupSearchController()
	{
		searchController=({
			let sc=UISearchController(searchResultsController: nil)
			sc.hidesNavigationBarDuringPresentation=false
			sc.dimsBackgroundDuringPresentation=false
			sc.searchBar.searchBarStyle=UISearchBarStyle.Minimal
			sc.searchBar.sizeToFit()
			return sc
			}())
		vc.rx_viewWillAppear.subscribeNext { _ in
			self.tableView.tableHeaderView=self.searchController.searchBar
			}.addDisposableTo(disposeBag)
		vc.rx_viewWillDisappear.subscribeNext{ _ in
			self.searchController.active=false
			self.searchController.searchBar.endEditing(true)
			if self.isSearching
			{
				// senno si comportava male...
				self.searchController.searchBar.removeFromSuperview()
			}
			}.addDisposableTo(disposeBag)
	}
	
	var isSearching:Bool {
		return (searchController.searchBar.text ?? "") != ""
	}
}
public enum OnSelectBehaviour<DataType>
{
	
	case Detail(segue:String)
	case Action(action:(d:DataType)->())
}
public class AutoSingleLevelTableViewManager<DataType where DataType:Visualizable,DataType:WithApi>:AutoSingleLevelTableView
{
	public typealias Data=DataType
	public var data:Observable<[Data]>!
	public let disposeBag=DisposeBag()
	public var dataBindDisposeBag=DisposeBag()
	public var viewModel=Data.defaultViewModel()
	public var vc:UIViewController!
	public var tableView:UITableView!
	
	var onClick:((row:Data)->())?=nil
	var clickedObj:Data?
	
	public init(){
	}
	public func setupTableView(tableView:UITableView,vc:UIViewController)
	{
		guard let nib=viewModel.cellNib else {
			fatalError("No cellNib defined: are you using ConcreteViewModel properly?")
		}
		
		self.vc=vc
		self.tableView=tableView
		
		switch nib
		{
		case .First(let nib):
			tableView.registerNib(nib, forCellReuseIdentifier: "cell")
		case .Second(let clazz):
			tableView.registerClass(clazz, forCellReuseIdentifier: "cell")
		}
		bindData()

		if let Cached=Data.self as? WithCachedApi.Type
		{
			let rc=UIRefreshControl()
			tableView.addSubview(rc)
			rc.rx_controlEvent(UIControlEvents.ValueChanged).subscribeNext{ _ in
				Cached.invalidateCache()
				self.dataBindDisposeBag=DisposeBag() // butto via la vecchia subscription
				self.bindData() // rifaccio la subscription
				rc.endRefreshing()
				}.addDisposableTo(disposeBag)
		}

		tableView
			.rx_modelSelected(Data.self)
			.subscribeNext { (obj) -> Void in
				self.clickedObj=obj
				self.onClick?(row: obj)
			}.addDisposableTo(disposeBag)
	}
	
	func bindData(){
		
		data=DataType.api(tableView).shareReplayLatestWhileConnected()
		
		data
			.bindTo(tableView.rx_itemsWithCellIdentifier("cell")) {
				(index,item,cell)->Void in
				self.viewModel.cellFactory(index,item: item,cell: cell)
				self.cellDecorators.forEach({ dec in
					dec(cell: cell)
				})
			}
			.addDisposableTo(dataBindDisposeBag)
		
		data
			.map { array in
				array.isEmpty
			}
			.subscribeNext { empty in
				if empty {
					self.tableView.backgroundView=self.viewModel.viewForEmptyList
				}
				else
				{
					self.tableView.backgroundView=nil
				}
		}.addDisposableTo(dataBindDisposeBag)
		
	}
	public typealias CellDecorator=(cell:UITableViewCell)->()
	public var cellDecorators:[CellDecorator]=[]
	
	public func setupOnSelect(onSelect:OnSelectBehaviour<Data>)
	{
		switch onSelect
		{
		case .Detail(let segue):
			let detailSegue=segue
			onClick={ row in
				self.vc.performSegueWithIdentifier(segue, sender: nil)
			}
			let dec:CellDecorator={ (cell:UITableViewCell) in
				cell.accessoryType=UITableViewCellAccessoryType.DisclosureIndicator
			}
			cellDecorators.append(dec)
			vc.rx_prepareForSegue.subscribeNext { (segue,_) in
				guard var dest=segue.destinationViewController as? DetailView,
					let identifier=segue.identifier else {return}
				if identifier==detailSegue
				{
					dest.detailManager.object=self.clickedObj
				}
				}.addDisposableTo(disposeBag)
		case .Action(let closure):
			self.onClick=closure
		}
	}
	
	
}

public class AutoSearchableSingleLevelTableViewManager<DataType where DataType:Visualizable,DataType:WithApi>:AutoSingleLevelTableViewManager<DataType>,Searchable
{
	public var searchController:UISearchController!
	
	public typealias FilteringClosure=(d:DataType,s:String)->Bool
	/// default closure don't filter anything
	public var filteringClosure:FilteringClosure
	public init(filteringClosure:FilteringClosure) {
		self.filteringClosure=filteringClosure
		super.init()
	}
	public override func setupTableView(tableView:UITableView,vc:UIViewController)
	{
		self.vc=vc
		self.tableView=tableView
		setupSearchController()
		super.setupTableView(tableView, vc:vc)
	}
	override func bindData() {
		data=DataType.api(tableView).shareReplayLatestWhileConnected()
		let search=searchController.searchBar.rx_text.asObservable()
		
		let dataOrSearch=Observable.combineLatest(data,search) {
			(d:[Data],s:String)->[Data] in
			switch s {
			case "": return d
			default:
				return d.filter {elem in self.filteringClosure(d:elem,s:s)}
			}
			}.shareReplayLatestWhileConnected()
		
		dataOrSearch
			.bindTo(tableView.rx_itemsWithCellIdentifier("cell")) {
				(index,item,cell)->Void in
				self.viewModel.cellFactory(index,item: item,cell: cell)
				self.cellDecorators.forEach({ dec in
					dec(cell: cell)
				})
			}
			.addDisposableTo(dataBindDisposeBag)
		
		dataOrSearch
			.map { array in
				array.isEmpty
			}
			.subscribeNext { empty in
				
				switch (empty,self.searchController.searchBar.text)
				{
				case (true,let s) where s==nil || s=="":
					self.tableView.backgroundView=self.viewModel.viewForEmptyList
				case (true,_):
					self.tableView.backgroundView=self.viewModel.viewForEmptySearch
				default:
					self.tableView.backgroundView=nil
				}
		}.addDisposableTo(dataBindDisposeBag)
		
	}
}



