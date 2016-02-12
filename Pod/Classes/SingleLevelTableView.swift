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

protocol ControllerWithTableView
{
	var tableView:UITableView! {get}
	var vc:UIViewController! {get}
}

let backgroundScheduler=OperationQueueScheduler(operationQueue: NSOperationQueue())



extension ControllerWithTableView where Self:Disposer
{
	func setupRefreshControl(invalidateCacheAndReBindData:()->())
	{
		// devo usare un tvc dummy perchè altrimenti RefreshControl si comporta male, il frame non è impostato correttamente.
		let rc=UIRefreshControl()
		let dummyTvc=UITableViewController()
		rc.backgroundColor=UIColor.clearColor()
		vc.addChildViewController(dummyTvc)
		dummyTvc.tableView=tableView
		tableView.bounces=true
		tableView.alwaysBounceVertical=true
		dummyTvc.refreshControl=rc
		rc.rx_controlEvent(UIControlEvents.ValueChanged).subscribeNext{ _ in
			invalidateCacheAndReBindData()
			rc.endRefreshing()
			}.addDisposableTo(disposeBag)
		
	}
}
public protocol AutoSingleLevelTableView:Disposer {
	typealias Data:Visualizable,WithApi
	typealias DataViewModel:ViewModel // where DataViewModel.Data==Data
	
	var viewModel:DataViewModel {get}
	var data:Observable<[Data]> {get}
	func setupTableView(tableView:UITableView,vc:UIViewController)
}

public typealias CellDecorator=(cell:UITableViewCell)->()

public enum SearchControllerStyle
{
	case SearchBarInTableHeader
	case SearchBarInNavigationBar
}

// non dovrebbe essere pubblico
protocol Searchable:class,ControllerWithTableView,Disposer
{
	var searchController:UISearchController! {get set}
	func setupSearchController(style:SearchControllerStyle)
}


extension Searchable
{
	
	/// To be called in viewDidLoad
	func setupSearchController(style:SearchControllerStyle)
	{
		searchController=({
			
			let sc=UISearchController(searchResultsController: nil)
			switch style{
			case .SearchBarInTableHeader:
				sc.hidesNavigationBarDuringPresentation=false
				sc.dimsBackgroundDuringPresentation=false
				sc.searchBar.searchBarStyle=UISearchBarStyle.Minimal
				sc.searchBar.backgroundColor=UIColor(white: 1.0, alpha: 0.95)
				sc.searchBar.sizeToFit()
			case .SearchBarInNavigationBar:
				sc.hidesNavigationBarDuringPresentation=false
				sc.dimsBackgroundDuringPresentation=false
				sc.searchBar.searchBarStyle=UISearchBarStyle.Prominent
				sc.searchBar.tintColor=UIColor(white:0.9, alpha:1.0) // non bianco altrimenti non si vede il cursore (influisce sul cursore e sul testo del pulsante cancel)
				sc.searchBar.sizeToFit()
			}
			return sc
			
			}())
		vc.rx_viewWillAppear.subscribeNext { _ in
			switch style{
			case .SearchBarInTableHeader:
				self.tableView.tableHeaderView=self.searchController.searchBar
			case .SearchBarInNavigationBar:
				self.vc.navigationItem.titleView=self.searchController.searchBar
				self.vc.definesPresentationContext=true
			}
			}.addDisposableTo(disposeBag)
		vc.rx_viewWillDisappear.subscribeNext{ _ in
			switch style{
			default:
				self.searchController.active=false
				self.searchController.searchBar.endEditing(true)
				if self.isSearching
				{
					// senno si comportava male...
					self.searchController.searchBar.removeFromSuperview()
				}
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

public class AutoSingleLevelTableViewManager<
	DataType,
	DataViewModel
	where DataType:Visualizable,
		DataType:WithApi,
		DataViewModel:ViewModel,
		DataViewModel.Data==DataType>
	
	:	AutoSingleLevelTableView,
		ControllerWithTableView
{
	public typealias Data=DataType
	public var data:Observable<[Data]> {
		return DataType.api(tableView)
			.subscribeOn(backgroundScheduler)
			.map {$0}
			.shareReplayLatestWhileConnected()
			.observeOn(MainScheduler.instance)
	}
	public let disposeBag=DisposeBag()
	public var dataBindDisposeBag=DisposeBag()
	public let viewModel:DataViewModel
	public var vc:UIViewController!
	public var tableView:UITableView!
	
	var onClick:((row:Data)->())?=nil
	var clickedObj:Data?
	
	public required init(viewModel:DataViewModel){
		self.viewModel=viewModel
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
		self.tableView.rowHeight=UITableViewAutomaticDimension
		self.tableView.estimatedRowHeight=100
		
		if let Cached=Data.self as? WithCachedApi.Type
		{
			setupRefreshControl{
				Cached.invalidateCache()
				self.dataBindDisposeBag=DisposeBag() // butto via la vecchia subscription
				self.bindData() // rifaccio la subscription
			}
		}
		
		tableView
			.rx_modelSelected(Data.self)
			.subscribeNext { (obj) -> Void in
				self.clickedObj=obj
				self.onClick?(row: obj)
			}.addDisposableTo(disposeBag)
	}
	
	func bindData(){
		data
			.bindTo(tableView.rx_itemsWithCellIdentifier("cell")) {
				(index,item,cell)->Void in
				self.viewModel.cellFactory(index,item: item, cell: cell as! DataViewModel.Cell)
				self.cellDecorators.forEach({ dec in
					dec(cell: cell)
				})
			}
			.addDisposableTo(dataBindDisposeBag)
		
		handleEmpty()
	}
	
	func handleEmpty()
	{
		data
			.map { array in
				array.isEmpty
			}
			.observeOn(MainScheduler.instance)
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

public class AutoSearchableSingleLevelTableViewManager<DataType,DataViewModel where DataType:Visualizable,DataType:WithApi,DataViewModel:ViewModel,DataViewModel.Data==DataType>:AutoSingleLevelTableViewManager<DataType,DataViewModel>,Searchable
{
	public var searchController:UISearchController!
	public typealias FilteringClosure=(d:DataType,s:String)->Bool
	public var filteringClosure:FilteringClosure
	let searchStyle:SearchControllerStyle
	public var search:Observable<String> {
		return searchController.searchBar.rx_textOrCancel.asObservable()
	}
	public override var data:Observable<[Data]> {
		let allData=DataType.api(tableView)
			.subscribeOn(backgroundScheduler)
			.map{$0}
			.observeOn(MainScheduler.instance)
			.shareReplayLatestWhileConnected()

		let dataOrSearch=Observable.combineLatest(allData,search) {
			(d:[Data],s:String)->[Data] in
			switch s {
			case "": return d
			default:
				return d.filter {elem in self.filteringClosure(d:elem,s:s)}
			}
			}.shareReplayLatestWhileConnected()
			.observeOn(MainScheduler.instance)
		
		return dataOrSearch
		
	}
	
	public init(viewModel:DataViewModel,filteringClosure:FilteringClosure,searchStyle:SearchControllerStyle = .SearchBarInNavigationBar) {
		self.searchStyle=searchStyle
		self.filteringClosure=filteringClosure
		super.init(viewModel: viewModel)
	}
	public override func setupTableView(tableView:UITableView,vc:UIViewController)
	{
		self.vc=vc
		self.tableView=tableView
		setupSearchController(searchStyle)
		super.setupTableView(tableView, vc:vc)
	}
	
	override func handleEmpty()
	{
		data
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



