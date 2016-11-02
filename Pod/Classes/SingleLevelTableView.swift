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


let backgroundScheduler=OperationQueueScheduler(operationQueue: OperationQueue())

public protocol AutoSingleLevelDataView:Disposer {
	associatedtype Data/*:WithApi*/
	associatedtype DataViewModel:ViewModel // where DataViewModel.Data==Data
	
	var viewModel:DataViewModel {get}
	var data:Observable<[Data]> {get}
}

public protocol AutoSingleLevelTableView:AutoSingleLevelDataView {
	func setupTableView(_ tableView:UITableView,vc:UIViewController)
}

public typealias CellDecorator=(_ cell:UITableViewCell)->()

public enum PresentationMode
{
	case push
//	case Popover(movableAnchor:UIView?)
}
public enum AccessoryStyle
{
	case info
	case detail
	case none
}

public enum OnSelectBehaviour<DataType>
{
	case segue(name:String,presentation:PresentationMode)
	case action(action:(_ d:DataType)->())
}
protocol TableViewDelegateCommon: UITableViewDelegate{
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle
}
extension TableViewDelegateCommon{
// NON SI PUO' IMPLEMENTARE DIRETTAMENTE I METODI O NON VERRANNO CHIAMATI DAL DELEGATE PROXY
	func _tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		return UITableViewCellEditingStyle.none
	}
}
class PopoverPresentationControllerDelegate:NSObject,UIPopoverPresentationControllerDelegate
{
	func adaptivePresentationStyle(for controller: UIPresentationController!) -> UIModalPresentationStyle {
		return .none
	}
}
let popoverPresentationControllerDelegate=PopoverPresentationControllerDelegate()

open class AutoSingleLevelTableViewManager<
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
	open var data:Observable<[Data]> {
		return dataExtractor.data()
	}
	open let disposeBag=DisposeBag()
	open var dataBindDisposeBag=DisposeBag()
	open let viewModel:DataViewModel
	open var vc:UIViewController!
	open var tableView:UITableView!
	open var dataExtractor:DataExtractorBase<Data>
	
	var onClick:((_ row:Data)->())?=nil
	var clickedObj:Data?
	
	public required init(viewModel:DataViewModel,dataExtractor:DataExtractorBase<Data>){
		self.viewModel=viewModel
		self.dataExtractor=dataExtractor
		self.dataExtractor.viewForActivityIndicator=tableView
	}
	open func setupTableView(_ tableView:UITableView,vc:UIViewController)
	{
		guard let nib=viewModel.cellNib else {
			DataVisualization.fatalError("No cellNib defined: are you using ConcreteViewModel properly?")
		}
		
		self.vc=vc
		self.tableView=tableView
		
		tableView.delegate=nil
		tableView.rx.setDelegate(self)
		
		registerDataCell(nib)
		setupRowSize()
		bindData()
		
		if let Cached=Data.self as? Cached.Type
		{
			setupRefreshControl{
				Cached.invalidateCache()
				self.dataBindDisposeBag=DisposeBag() // butto via la vecchia subscription
				self.bindData() // rifaccio la subscription
			}
		}
		
		func didSelectObj(_ obj:Data)
		{
			self.clickedObj=obj
			self.onClick?(obj)
			tableView.indexPathsForSelectedRows?.forEach{ (indexPath) in
				tableView.deselectRow(at: indexPath, animated: true)
			}
		}
		
		tableView
			.rx.modelSelected(Data.self)
			.subscribe(onNext:(didSelectObj))
			.addDisposableTo(disposeBag)
		
		tableView
			.rx.itemAccessoryButtonTapped
			.subscribe(onNext: { (index) in
				if let obj:Data=try? tableView.rx.model(at:index) {
					tableView.selectRow(at: index, animated: false, scrollPosition: UITableViewScrollPosition.none)
					didSelectObj(obj)
				}
		}).addDisposableTo(disposeBag)
		
	}
	
	func bindData(){
		data
			.bindTo(tableView.rx.items(cellIdentifier:"cell")) {
				(index,item,cell)->Void in
				self.viewModel.cellFactory(index,item: item, cell: cell as! DataViewModel.Cell)
				cell.setNeedsUpdateConstraints()
				cell.updateConstraintsIfNeeded()
				self.cellDecorators.forEach({ dec in
					dec(cell)
				})
			}
			.addDisposableTo(dataBindDisposeBag)
		
		handleEmpty()
	}
	open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		return _tableView(tableView, editingStyleForRowAt: indexPath)
	}
	
	func handleEmpty()
	{
		data
			.map { array in
				array.isEmpty
			}
			.observeOn(MainScheduler.instance)
			.subscribe(onNext: { empty in
				if empty {
					self.tableView.backgroundView=self.viewModel.viewForEmptyList
				}
				else
				{
					self.tableView.backgroundView=nil
				}
			}).addDisposableTo(dataBindDisposeBag)
		
	}
	open var cellDecorators:[CellDecorator]=[]
	
	open func setupOnSelect(_ accessory:AccessoryStyle,_ onSelect:OnSelectBehaviour<Data>)
	{
		func prepareSegue(_ segue:String,presentation:PresentationMode)
		{
			let detailSegue=segue
			onClick={ _ in self.vc.performSegue(withIdentifier: segue, sender: nil) }
			vc.rx_prepareForSegue.subscribe(onNext: { (segue,_) in
				guard let destVC=segue.destination as? UIViewController,
					let identifier=segue.identifier else {return}
				
				if identifier==detailSegue {
					guard var dest=segue.destination as? DetailView
						else {return}
					dest.detailManager.object=self.clickedObj
				}
				}).addDisposableTo(disposeBag)
		}
		switch accessory
		{
		case .detail:
			let dec:CellDecorator={ (cell:UITableViewCell) in
				cell.accessoryType=UITableViewCellAccessoryType.disclosureIndicator
			}
			cellDecorators.append(dec)
		case .info:
			let dec:CellDecorator={ (cell:UITableViewCell) in
				cell.accessoryType=UITableViewCellAccessoryType.detailButton
			}
			cellDecorators.append(dec)
		case .none:
			_=0
		}
		switch onSelect
		{
		case .segue(let name,let presentation):
			prepareSegue(name,presentation: presentation)
			
		case .action(let closure):
			self.onClick=closure
		}
	}
	
	
}

open class AutoSearchableSingleLevelTableViewManager<
	DataType,
	DataViewModel
	where
	DataViewModel:ViewModel,
	DataViewModel.Data==DataType>
	
	: AutoSingleLevelTableViewManager<DataType,DataViewModel>,
	Searchable
{
	open var searchController:UISearchController!
	public typealias FilteringClosure=(_ d:DataType,_ s:String)->Bool
	open var filteringClosure:FilteringClosure
	let searchStyle:SearchControllerStyle
	open var search:Observable<String> {
		guard let searchBar=searchController.searchBar as? CustomSearchBar else {DataVisualization.fatalError()}
		return searchBar.rx_textOrCancel.asObservable()
	}
	open override var data:Observable<[Data]> {
		let allData=super.data
		
		let dataOrSearch=Observable.combineLatest(allData,search) {
			(d:[Data],s:String)->[Data] in
			switch s {
			case "": return d
			default:
				return d.filter {elem in self.filteringClosure(elem,s)}
			}
			}.shareReplayLatestWhileConnected()
			.observeOn(MainScheduler.instance)
		
		return dataOrSearch
		
	}
	
	public init(viewModel:DataViewModel,filteringClosure:@escaping FilteringClosure,searchStyle:SearchControllerStyle = .searchBarInNavigationBar,dataExtractor:DataExtractorBase<Data>) {
		self.searchStyle=searchStyle
		self.filteringClosure=filteringClosure
		super.init(viewModel: viewModel,dataExtractor:dataExtractor)
	}
	
	public required init(viewModel: DataViewModel, dataExtractor: DataExtractorBase<Data>) {
		fatalError("init(viewModel:dataExtractor:) has not been implemented")
	}
	open override func setupTableView(_ tableView:UITableView,vc:UIViewController)
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
			.subscribe(onNext: { empty in
				
				switch (empty,self.searchController.searchBar.text)
				{
				case (true,let s) where s==nil || s=="":
					self.tableView.backgroundView=self.viewModel.viewForEmptyList
				case (true,_):
					self.tableView.backgroundView=self.viewModel.viewForEmptySearch
				default:
					self.tableView.backgroundView=nil
				}
			}).addDisposableTo(dataBindDisposeBag)
		
	}
}



