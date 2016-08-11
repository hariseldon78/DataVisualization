//
//  TableView.swift
//  DataVisualization
//
//  Created by Roberto Previdi on 28/12/15.
//  Copyright © 2015 Municipium. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Cartography

public protocol Disposer {
	var disposeBag:DisposeBag {get}
}


let backgroundScheduler=OperationQueueScheduler(operationQueue: NSOperationQueue())

public protocol AutoSingleLevelDataView:Disposer {
	typealias Data/*:WithApi*/
	typealias DataViewModel:ViewModel // where DataViewModel.Data==Data
	
	var viewModel:DataViewModel {get}
	var data:Observable<[Data]> {get}
}

public protocol AutoSingleLevelTableView:AutoSingleLevelDataView {
	func setupTableView(tableView:UITableView,vc:UIViewController)
}

public typealias CellDecorator=(cell:UITableViewCell)->()

public enum PresentationMode
{
	case Push
//	case Popover(movableAnchor:UIView?)
}
public enum AccessoryStyle
{
	case Info
	case Detail
	case None
}

public enum OnSelectBehaviour<DataType>
{
	case Segue(name:String,presentation:PresentationMode)
	case Action(action:(d:DataType)->())
}
protocol TableViewDelegateCommon: UITableViewDelegate{
	func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle
}
extension TableViewDelegateCommon{
// NON SI PUO' IMPLEMENTARE DIRETTAMENTE I METODI O NON VERRANNO CHIAMATI DAL DELEGATE PROXY
	func _tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
		return UITableViewCellEditingStyle.None
	}
}
class PopoverPresentationControllerDelegate:NSObject,UIPopoverPresentationControllerDelegate
{
	func adaptivePresentationStyleForPresentationController(controller: UIPresentationController!) -> UIModalPresentationStyle {
		return .None
	}
}
let popoverPresentationControllerDelegate=PopoverPresentationControllerDelegate()

public class AutoSingleLevelTableViewManager<
	DataType,
	DataViewModel
	where
	DataViewModel:ViewModel,
	DataViewModel.Data==DataType>
	
	:	NSObject,
	AutoSingleLevelTableView,
	TableViewDelegateCommon,
	ControllerWithTableView
{
	public typealias Data=DataType
	public var data:Observable<[Data]> {
		return dataExtractor.data()
	}
	public let disposeBag=DisposeBag()
	public var dataBindDisposeBag=DisposeBag()
	public let viewModel:DataViewModel
	public var vc:UIViewController!
	public var tableView:UITableView!
	public var dataExtractor:DataExtractorBase<Data>
	
	var onClick:((row:Data)->())?=nil
	var clickedObj:Data?
	
	public required init(viewModel:DataViewModel,dataExtractor:DataExtractorBase<Data>){
		self.viewModel=viewModel
		self.dataExtractor=dataExtractor
		self.dataExtractor.viewForActivityIndicator=tableView
	}
	public func setupTableView(tableView:UITableView,vc:UIViewController)
	{
		guard let nib=viewModel.cellNib else {
			DataVisualization.fatalError("No cellNib defined: are you using ConcreteViewModel properly?")
		}
		
		self.vc=vc
		self.tableView=tableView

		tableView.rx_setDelegate(self)
		
		registerDataCell(nib)
		setupRowSize()
		bindData()
		
		if let Cached=Data.self as? WithCachedApi.Type
		{
			setupRefreshControl{
				Cached.invalidateCache()
				self.dataBindDisposeBag=DisposeBag() // butto via la vecchia subscription
				self.bindData() // rifaccio la subscription
			}
		}
		
		func didSelectObj(obj:Data)
		{
			self.clickedObj=obj
			self.onClick?(row: obj)
			tableView.indexPathsForSelectedRows?.forEach{ (indexPath) in
				tableView.deselectRowAtIndexPath(indexPath, animated: true)
			}
		}
		
		tableView
			.rx_modelSelected(Data.self)
			.subscribeNext(didSelectObj)
			.addDisposableTo(disposeBag)
		
		tableView
			.rx_itemAccessoryButtonTapped
			.subscribeNext { (index) in
				if let obj:Data=try? tableView.rx_modelAtIndexPath(index) {
					tableView.selectRowAtIndexPath(index, animated: false, scrollPosition: UITableViewScrollPosition.None)
					didSelectObj(obj)
				}
		}
		
	}
	
	func bindData(){
		data
			.bindTo(tableView.rx_itemsWithCellIdentifier("cell")) {
				(index,item,cell)->Void in
				self.viewModel.cellFactory(index,item: item, cell: cell as! DataViewModel.Cell)
				cell.setNeedsUpdateConstraints()
				cell.updateConstraintsIfNeeded()
				self.cellDecorators.forEach({ dec in
					dec(cell: cell)
				})
			}
			.addDisposableTo(dataBindDisposeBag)
		
		handleEmpty()
	}
	public func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
		return _tableView(tableView, editingStyleForRowAtIndexPath: indexPath)
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
	
	public func setupOnSelect(accessory:AccessoryStyle,_ onSelect:OnSelectBehaviour<Data>)
	{
		func prepareSegue(segue:String,presentation:PresentationMode)
		{
			let detailSegue=segue
			onClick={ _ in self.vc.performSegueWithIdentifier(segue, sender: nil) }
			vc.rx_prepareForSegue.subscribeNext { (segue,_) in
				guard let destVC=segue.destinationViewController as? UIViewController,
					let identifier=segue.identifier else {return}
				
				if identifier==detailSegue {
					guard var dest=segue.destinationViewController as? DetailView
						else {return}
					dest.detailManager.object=self.clickedObj
				}
				}.addDisposableTo(disposeBag)
		}
		switch accessory
		{
		case .Detail:
			let dec:CellDecorator={ (cell:UITableViewCell) in
				cell.accessoryType=UITableViewCellAccessoryType.DisclosureIndicator
			}
			cellDecorators.append(dec)
		case .Info:
			let dec:CellDecorator={ (cell:UITableViewCell) in
				cell.accessoryType=UITableViewCellAccessoryType.DetailButton
			}
			cellDecorators.append(dec)
		case .None:
			_=0
		}
		switch onSelect
		{
		case .Segue(let name,let presentation):
			prepareSegue(name,presentation: presentation)
			
		case .Action(let closure):
			self.onClick=closure
		}
	}
	
	
}

public class AutoSearchableSingleLevelTableViewManager<
	DataType,
	DataViewModel
	where
	DataViewModel:ViewModel,
	DataViewModel.Data==DataType>
	
	: AutoSingleLevelTableViewManager<DataType,DataViewModel>,
	Searchable
{
	public var searchController:UISearchController!
	public typealias FilteringClosure=(d:DataType,s:String)->Bool
	public var filteringClosure:FilteringClosure
	let searchStyle:SearchControllerStyle
	public var search:Observable<String> {
		guard let searchBar=searchController.searchBar as? CustomSearchBar else {DataVisualization.fatalError()}
		return searchBar.rx_textOrCancel.asObservable()
	}
	public override var data:Observable<[Data]> {
		let allData=super.data
		
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
	
	public init(viewModel:DataViewModel,filteringClosure:FilteringClosure,searchStyle:SearchControllerStyle = .SearchBarInNavigationBar,dataExtractor:DataExtractorBase<Data>) {
		self.searchStyle=searchStyle
		self.filteringClosure=filteringClosure
		super.init(viewModel: viewModel,dataExtractor:dataExtractor)
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



