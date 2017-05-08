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
	var 🗑:DisposeBag {get}
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

public typealias CellDecorator<DataType>=(_ cell:UITableViewCell, _ data:DataType)->()

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
	func asUIKitType() -> UITableViewCellAccessoryType {
		switch self {
		case .info:
			return .detailButton
		case .detail:
			return .disclosureIndicator
		case .none:
			return .none
		}
	}
}

public enum OnSelectBehaviour<DataType>
{
	case segue(name:String,presentation:PresentationMode)
	case action(action:(_ d:DataType)->())
	case none
}

public enum SelectionStyle<DataType> {
	case allTheSame(style:AccessoryStyle,behaviour:OnSelectBehaviour<DataType>)
	// provide a PURE closure
	case conditional((DataType)->(style:AccessoryStyle,behaviour:OnSelectBehaviour<DataType>))
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
	open let 🗑=DisposeBag()
	open let viewModel:DataViewModel
	open var vc:UIViewController!
	open var tableView:UITableView!
	open var dataExtractor:DataExtractorBase<Data>

	var onClick:((_ row:Data)->())?=nil
	// roba inizializzata alla selezione
	var detailSegue:String?
	var clickedObj:Data?
	
	public required init(viewModel:DataViewModel,dataExtractor:DataExtractorBase<Data>){
		self.viewModel=viewModel
		self.dataExtractor=dataExtractor
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
			setupRefreshControl(refreshData)
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
			.addDisposableTo(🗑)
		
		tableView
			.rx.itemAccessoryButtonTapped
			.subscribe(onNext: { (index) in
				if let obj:Data=try? tableView.rx.model(at:index) {
					tableView.selectRow(at: index, animated: false, scrollPosition: UITableViewScrollPosition.none)
					didSelectObj(obj)
				}
		}).addDisposableTo(🗑)
		
	}
	open func refreshData(atEnd:@escaping ()->()) {
		guard let Cached=Data.self as? Cached.Type else {return}

		Cached.invalidateCache()
		
		dataExtractor
			.refresh(hideProgress: true)
		
		data
			.map {_ in return ()}
			.take(1)
			.subscribe(onNext:{
				atEnd()
			})
			.addDisposableTo(self.🗑)
		
	}
	@discardableResult func bindData()->Observable<Void> {
		let data=self.data.shareReplayLatestWhileConnected()

		data
			.bindTo(tableView.rx.items(cellIdentifier:"cell")) {
				(index,item,cell)->Void in
				self.viewModel.cellFactory(index,item: item, cell: cell as! DataViewModel.Cell)
				cell.setNeedsUpdateConstraints()
				cell.updateConstraintsIfNeeded()
				self.cellDecorators.forEach({ dec in
					dec(cell,item)
				})
			}
			.addDisposableTo(🗑)
		
		handleEmpty(data:data)
		
		return data.map{_ in return ()}
	}
	open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		return _tableView(tableView, editingStyleForRowAt: indexPath)
	}
	
	func handleEmpty(data:Observable<[Data]>)
	{
		data
			.map { array in
				array.isEmpty
			}
			.observeOn(MainScheduler.instance)
			.subscribe(
				onNext: { empty in
					if empty {
						self.tableView.backgroundView=self.viewModel.viewForEmptyList
					}
					else
					{
						self.tableView.backgroundView=nil
					}
			},
				onError:{ _ in
					self.tableView.backgroundView=self.viewModel.viewForDataError
			}).addDisposableTo(🗑)
		
	}
	open var cellDecorators:[CellDecorator<Data>]=[]
	
	open func setupOnSelect(_ style:SelectionStyle<Data>)
	{
		func prepareSegue(_ segue:String,presentation:PresentationMode)
		{
			detailSegue=segue
			onClick={ _ in
				self.vc.performSegue(withIdentifier: segue, sender: nil)
			}
			vc.rx_prepareForSegue.subscribe(onNext: { (segue,_) in
				guard let destVC=segue.destination as? UIViewController,
					let identifier=segue.identifier else {return}
				
				if identifier==self.detailSegue {
					guard var dest=segue.destination as? DetailView
						else {return}
					dest.detailManager.object=self.clickedObj
				}
				}).addDisposableTo(🗑)
		}
		
		switch style {
		case .allTheSame(let accessory, let behaviour):
			let dec:CellDecorator={ (cell:UITableViewCell,_:Data) in
				cell.accessoryType=accessory.asUIKitType()
			}
			cellDecorators.append(dec)
			switch behaviour
			{
			case .segue(let name,let presentation):
				prepareSegue(name,presentation: presentation)
				
			case .action(let closure):
				self.onClick=closure
			case .none:
				_=0
			}
			
		case .conditional(let f):
			let dec:CellDecorator={ (cell:UITableViewCell,data:Data) in
				let (accessory,_)=f(data)
				cell.accessoryType=accessory.asUIKitType()
			}
			cellDecorators.append(dec)

			onClick={data in
				let (_,behaviour)=f(data)
				
				switch behaviour
				{
				case .segue(let name,let presentation):
					self.detailSegue=name
					self.vc.performSegue(withIdentifier: name, sender: nil)
					self.vc.rx_prepareForSegue.subscribe(onNext: { (segue,_) in
						guard let destVC=segue.destination as? UIViewController,
							let identifier=segue.identifier else {return}
						
						if identifier==self.detailSegue {
							guard var dest=segue.destination as? DetailView
								else {return}
							dest.detailManager.object=self.clickedObj
						}
					}).addDisposableTo(self.🗑)
					
				case .action(let closure):
					closure(data)
				case .none:
					_=0
				}
			}
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
	open var searchController:CustomSearchController!
	public typealias FilteringClosure=(_ d:DataType,_ s:String)->Bool
	open var filteringClosure:FilteringClosure
	let searchStyle:SearchControllerStyle
	open var search:Observable<String> {
		return Observable.of(searchController.searchBar.rx_textOrCancel.asObservable(),searchController.searchProgrammatically).merge()
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
	
	public init(viewModel:DataViewModel,filteringClosure:@escaping FilteringClosure,searchStyle:SearchControllerStyle = SearchControllerStyle(),dataExtractor:DataExtractorBase<Data>) {
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
	
	override func handleEmpty(data:Observable<[Data]>)
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
			}).addDisposableTo(🗑)
		
	}
}



