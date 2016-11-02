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
import RxDataSources

public protocol Sectioner
{
	//	init(viewForActivityIndicator:UIView?)
	var viewForActivityIndicator:UIView? {get set}
	associatedtype Data
	associatedtype Section
	var sections:Observable<[(Section,[Data])]> {get}
	mutating func resubscribe()
}

public enum SectionCollapseState
{
	case expanded
	case collapsed
	public var char:String {
		switch self
		{
		case .expanded:
			return "v"
		case .collapsed:
			return ">"
		}
	}
}
public protocol CollapsableSection:Equatable
{
	var collapseState:SectionCollapseState {get set}
	var elementsCount:Int {get set} // FIXME: seems a bad hack...
}
public protocol CollapsableSectionerProtocol:Sectioner
{
	associatedtype Section:CollapsableSection
	var showAll:Variable<Bool> {get set}
	var selectedSection:Variable<Section?> {get set}
}
open class CollapsableSectioner<
	OriginalSectioner where
	OriginalSectioner:Sectioner,
	OriginalSectioner:Cached,
	OriginalSectioner.Section:CollapsableSection>
	:CollapsableSectionerProtocol,Cached
{
	public typealias Data=OriginalSectioner.Data
	public typealias Section=OriginalSectioner.Section
	public typealias SectionAndData=(Section,[Data])
	open var showAll=Variable(false)
	open var selectedSection=Variable<OriginalSectioner.Section?>(nil)
	open var original:OriginalSectioner
	public init(original:OriginalSectioner)
	{
		self.original=original
	}
	open var sections:Observable<[SectionAndData]> {
		return Observable.combineLatest(original.sections,selectedSection.asObservable(),showAll.asObservable())
		{
			let (sectionsAndData,selected,showAll)=$0
			return sectionsAndData.map{ (_s,dd)  in
				var s=_s
				s.elementsCount=dd.count
				if showAll || (selected != nil && s==selected!)
				{
					s.collapseState = .expanded
					return (s,dd)
				}
				else
				{
					s.collapseState = .collapsed
					return (s,[Data]())
				}
			}
		}
	}
	open func resubscribe() {
		original.resubscribe()
	}
	
	open var viewForActivityIndicator: UIView? {
		get {return original.viewForActivityIndicator}
		set(x) {original.viewForActivityIndicator=x}
	}
	
	
	open static func invalidateCache() {
		OriginalSectioner.invalidateCache()
	}
}

public protocol AutoSectionedTableView:Disposer {
	associatedtype Element
	associatedtype ElementViewModel
	associatedtype Section
	associatedtype SectionViewModel
	associatedtype SectionerType:Sectioner
	
	var elementViewModel:ElementViewModel {get}
	var sectionViewModel:SectionViewModel {get}
	
	func setupTableView(_ tableView:UITableView,vc:UIViewController)
	var sectioner:SectionerType {get}
}
class EnrichedTapGestureRecognizer<T>:UITapGestureRecognizer
{
	var obj:T
	init(target: AnyObject?, action: Selector,obj:T) {
		self.obj=obj
		super.init(target: target, action: action)
	}
}
public enum OnSelectSectionedBehaviour<T>
	// i can't inherit the cases from OnSelectBehaviour so i need to duplicate a lot of code :(...
{
	case segue(name:String,presentation:PresentationMode)
	case sectionSegue(name:String,presentation:PresentationMode) // shows the detail of the section, even if starting from a data cell
	case indexPathSpecificSegue(segueForPath:(IndexPath)->String,presentation:PresentationMode)
	case action(action:(_ d:T)->())
}


open class AutoSectionedTableViewManager<
	_Element,
	_ElementViewModel,
	_Section,
	_SectionViewModel,
	_Sectioner
	where
	_ElementViewModel:ViewModel,
	_ElementViewModel.Data==_Element,
	_SectionViewModel:SectionViewModel,
	_SectionViewModel.Section==_Section,
	_SectionViewModel.Element==_Element,
	_Sectioner:Sectioner,
	_Sectioner.Data==_Element,
	_Sectioner.Section==_Section>
	
	:	NSObject,
	AutoSectionedTableView,
	TableViewDelegateCommon,
	ControllerWithTableView
{
	open let disposeBag=DisposeBag()
	open var dataBindDisposeBag=DisposeBag()
	public typealias Element=_Element
	public typealias ElementViewModel=_ElementViewModel
	public typealias Section=_Section
	public typealias SectionViewModel=_SectionViewModel
	public typealias SectionerType=_Sectioner
	
	public typealias SectionAndData=(Section,[Element])
	
	typealias RxSectionModel=SectionModel<Section,Element>
	let dataSource=RxTableViewSectionedReloadDataSource<RxSectionModel>()
	var sections=Variable([RxSectionModel]())
	
	var onDataClick:((_ row:Element,_ path:IndexPath)->())?=nil
	var clickedDataObj:Element?
	
	var onSectionClick:((_ section:Section)->())?=nil
	var clickedSectionObj:Section?
	
	open var elementViewModel:ElementViewModel
	open var sectionViewModel:SectionViewModel
	open var sectioner:SectionerType
	var vc:UIViewController!
	var tableView:UITableView!
	
	
	
	public init(
		elementViewModel:ElementViewModel,
		sectionViewModel:SectionViewModel,
		sectioner:SectionerType)
	{
		self.elementViewModel=elementViewModel
		self.sectionViewModel=sectionViewModel
		self.sectioner=sectioner
		super.init()
	}
	open func setupTableView(_ tableView:UITableView,vc:UIViewController)
	{
		guard let dataNib=elementViewModel.cellNib,
			let sectionNib=sectionViewModel.cellNib
			else {
				DataVisualization.fatalError("No cellNib defined: are you using ConcreteViewModel properly?")
		}
		
		self.vc=vc
		self.tableView=tableView
		sectioner.viewForActivityIndicator=self.tableView
		
		tableView.rx.setDelegate(self)
		registerDataCell(dataNib)
		registerSectionCell(sectionNib)
		setupRowSize()
		setupSectionSize()
		
		dataSource.configureCell={
			(dataSource,tableView,indexPath,item:Element) in
			guard let cell=tableView.dequeueReusableCell(withIdentifier: "cell")
				else {
					DataVisualization.fatalError("why no cell?")
			}
			self.elementViewModel.cellFactory(
				indexPath.row, item: item, cell: cell as! ElementViewModel.Cell)
			cell.setNeedsUpdateConstraints()
			cell.updateConstraintsIfNeeded()
			self.cellDecorators.forEach({ dec in
				dec(cell)
			})
			return cell
		}
		setDataSource()
		bindData()
		
		if let Cacheable=SectionerType.self as? Cached.Type
		{
			setupRefreshControl{
				Cacheable.invalidateCache()
				self.sectioner.resubscribe()
				self.dataBindDisposeBag=DisposeBag()
				self.bindData()
			}
		}
		tableView
			.rx.itemAccessoryButtonTapped
			.subscribe(onNext: { (index) in
				if let obj:Element=try? tableView.rx.model(at:index) {
					self.tableView.selectRow(at: index, animated: false, scrollPosition: UITableViewScrollPosition.none)
					self.tableView(self.tableView, didSelectRowAt: index)
				}
		}).addDisposableTo(disposeBag)
		
	}
	var emptyList=false
	open var data:Observable<[SectionAndData]> {
		return sectioner.sections
	}
	func setDataSource()
	{
		tableView.dataSource=nil
		sections.asObservable()
			.observeOn(MainScheduler.instance)
			.bindTo(tableView.rx.items(dataSource:dataSource))
			.addDisposableTo(disposeBag)
	}
	func bindData()
	{
		data
			.debug("data")
			.subscribeOn(backgroundScheduler)
			.debug("backgroundScheduler")
			.subscribe(onNext: { (secs:[(Section, [Element])]) -> Void in
				self.sections.value=secs.map{ (s,d) in
					RxSectionModel(model: s, items: d)
				}
				self.emptyList=secs.isEmpty
				if self.emptyList {
					self.tableView.backgroundView=self.sectionViewModel.viewForEmptyList
				} else {
					self.tableView.backgroundView=nil
				}
			})
			.addDisposableTo(dataBindDisposeBag)
		
	}
	open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		return _tableView(tableView, editingStyleForRowAt: indexPath)
	}
	open func tableView(_ tableView: UITableView,
	                    viewForHeaderInSection section: Int) -> UIView?
	{
		guard let hv=tableView.dequeueReusableHeaderFooterView(withIdentifier: "section")
			else {
				DataVisualization.fatalError("why no section cell?")
		}
		guard section<sections.value.count else {return nil}
		let sec=sections.value[section]
		
		sectionViewModel.cellFactory(section, item:sec.model, elements:sec.items, cell:hv as! SectionViewModel.Cell)
		if onSectionClick != nil
		{
			let gestRec=EnrichedTapGestureRecognizer(target: self, action: "sectionTitleTapped:",obj:sec.model)
			hv.addGestureRecognizer(gestRec)
		}
		
		return hv
	}
	func sectionTitleTapped(_ gr:UITapGestureRecognizer)
	{
		guard let gr=gr as? EnrichedTapGestureRecognizer<Section> else {return}
		clickedSectionObj=gr.obj
		onSectionClick?(gr.obj)
	}
	//	public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
	//		guard let hv=tableView.dequeueReusableHeaderFooterViewWithIdentifier("section")
	//			else {fatalError("why no section cell?")}
	//		return hv.bounds.height
	//	}
	open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		dump(indexPath)
		let item=dataSource[indexPath]
		clickedDataObj=item
		clickedSectionObj=sections.value[indexPath.section].model
		onDataClick?(item,indexPath)
		tableView.indexPathsForSelectedRows?.forEach{ (indexPath) in
			tableView.deselectRow(at: indexPath, animated: true)
		}
		
	}
	
	open var cellDecorators:[CellDecorator]=[]
	
	var dataDetailSegue:String?=nil
	var dataDetailSectionSegue:String?=nil
	open func setupDataOnSelect(_ accessory:AccessoryStyle,_ onSelect:OnSelectSectionedBehaviour<Element>)
	{
		switch onSelect
		{
		case .segue(let name,let presentation):
			dataDetailSegue=name
			onDataClick = { row,_ in
				self.vc.performSegue(withIdentifier: name, sender: nil)
			}
		case .sectionSegue(let name,let presentation):
			dataDetailSectionSegue=name
			onDataClick = { row,_ in
				self.vc.performSegue(withIdentifier: name, sender: nil)
			}
		case .indexPathSpecificSegue(let segueForPath,let presentation):
			onDataClick = { _,indexPath in
				self.vc.performSegue(withIdentifier: segueForPath(indexPath), sender: nil)
			}
		case .action(let closure):
			self.onDataClick={d,_ in closure(d)}
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
		case .segue(_,_):
			fallthrough
		case .sectionSegue(_,_):
			fallthrough
		case .indexPathSpecificSegue(_,_):
			listenForSegue()
		default:
			_=0
		}
	}
	var sectionDetailSegue:String?=nil
	open func setupSectionOnSelect(_ onSelect:OnSelectBehaviour<Section>)
	{
		func prepareSegue(_ segue:String)
		{
			sectionDetailSegue=segue
			onSectionClick = { row in
				self.vc.performSegue(withIdentifier: segue, sender: nil)
			}
			listenForSegue()
		}
		switch onSelect
		{
		//FIXME: Supportare popover anche con sections
		case .segue(let segue,_):
			prepareSegue(segue)
			
		case .action(let closure):
			self.onSectionClick=closure
		}
	}
	var listeningForSegue=false
	open func listenForSegue() {
		guard !listeningForSegue else {return}
		listeningForSegue=true
		vc.rx_prepareForSegue.subscribe(onNext: { (segue,_) in
			guard var dest=segue.destination as? DetailView,
				let identifier=segue.identifier else {return}
			switch identifier
			{
			case let val where val==self.dataDetailSegue:
				dest.detailManager.object=self.clickedDataObj
			case let val where val==self.dataDetailSectionSegue:
				dest.detailManager.object=self.clickedSectionObj
			case let val where val==self.sectionDetailSegue:
				dest.detailManager.object=self.clickedSectionObj
			default:
				dest.detailManager.object=self.clickedDataObj
			}
		}).addDisposableTo(disposeBag)
	}
}

open class AutoSearchableSectionedTableViewManager<
	_Element,
	_ElementViewModel,
	_Section,
	_SectionViewModel,
	_Sectioner
	where
	_ElementViewModel:ViewModel,
	_ElementViewModel.Data==_Element,
	_SectionViewModel:SectionViewModel,
	_SectionViewModel.Section==_Section,
	_SectionViewModel.Element==_Element,
	_Sectioner:Sectioner,
	_Sectioner.Data==_Element,
	_Sectioner.Section==_Section>
	
	:AutoSectionedTableViewManager<_Element,
	_ElementViewModel,
	_Section,
	_SectionViewModel,
	_Sectioner>,
	Searchable
{
	open var searchController:UISearchController!
	open override func setupTableView(_ tableView:UITableView,vc:UIViewController)
	{
		self.vc=vc
		self.tableView=tableView
		setupSearchController(searchStyle)
		super.setupTableView(tableView, vc:vc)
	}
	public typealias DataFilteringClosure=(_ d:Element,_ s:String)->Bool
	public typealias SectionFilteringClosure=(_ d:Section,_ s:String)->Bool
	open var search:Observable<String> {
		guard let searchBar=searchController.searchBar as? CustomSearchBar else {DataVisualization.fatalError()}
		return searchBar.rx_textOrCancel.asObservable()
	}
	open var allData:Observable<[SectionAndData]> {
		return sectioner.sections.subscribeOn(backgroundScheduler).shareReplayLatestWhileConnected()
	}
	open func searchObserver(
		_ allData:Observable<[SectionAndData]>,
		search:Observable<String>)->Observable<[SectionAndData]>
	{
		return Observable.combineLatest(
			allData,
			search,
			resultSelector: {
				(d:[SectionAndData], s:String) -> [SectionAndData] in
				switch s
				{
				case "": return d
				default:
					var res=[SectionAndData]()
					for (sec,data) in d
					{
						if self.sectionFilteringClosure(sec, s)
						{
							res.append((sec,data))
							continue
						}
						
						var matchingData=[Element]()
						for item in data
						{
							if self.dataFilteringClosure(item, s)
							{
								matchingData.append(item)
							}
						}
						if !matchingData.isEmpty
						{
							res.append((sec,matchingData))
						}
					}
					return res
				}
		})
			.shareReplayLatestWhileConnected()
			.observeOn(MainScheduler.instance)
	}
	open override var data:Observable<[SectionAndData]> {
		return searchObserver(allData, search: search)
	}
	
	open var dataFilteringClosure:DataFilteringClosure
	open var sectionFilteringClosure:SectionFilteringClosure
	let searchStyle:SearchControllerStyle
	
	public init(elementViewModel:ElementViewModel,
	            sectionViewModel:SectionViewModel,
	            sectioner:SectionerType,
	            dataFilteringClosure:@escaping DataFilteringClosure,
	            sectionFilteringClosure:@escaping SectionFilteringClosure,
	            searchStyle:SearchControllerStyle = .searchBarInNavigationBar)
	{
		self.searchStyle=searchStyle
		self.dataFilteringClosure=dataFilteringClosure
		self.sectionFilteringClosure=sectionFilteringClosure
		super.init(elementViewModel:elementViewModel,sectionViewModel:sectionViewModel,sectioner: sectioner)
	}
	
	var dataCompleted=false
	override func bindData() {
		data.subscribe(onNext: {
			(secs:[(Section, [Element])]) -> Void in
			self.sections.value=secs.map{
				(s,d) in
				RxSectionModel(model: s, items: d)
			}
			self.tableView.dataSource=nil
			self.sections.asObservable()
				.observeOn(MainScheduler.instance)
				.bindTo(self.tableView.rx.items(dataSource:self.dataSource))
				.addDisposableTo(self.dataBindDisposeBag)
			}).addDisposableTo(dataBindDisposeBag)
		
		
		allData.map { array in
			array.isEmpty
			}
			.subscribe(onNext: { (empty) -> Void in
				self.emptyList=empty
				}, onError: nil,
				   onCompleted: { () -> Void in
					self.dataCompleted=true
				}, onDisposed: nil)
			.addDisposableTo(dataBindDisposeBag)
		
		data
			.map { array in
				array.isEmpty
			}
			.observeOn(MainScheduler.instance)
			.subscribe(onNext: { empty in
				
				switch (empty,self.searchController.searchBar.text)
				{
				case (true,let s) where self.dataCompleted && self.emptyList && (s==nil || s==""):
					self.tableView.backgroundView=self.sectionViewModel.viewForEmptyList
				case (true,let s) where s != nil && s! != "":
					self.tableView.backgroundView=self.sectionViewModel.viewForEmptySearch
				default:
					self.tableView.backgroundView=nil
				}
			}).addDisposableTo(dataBindDisposeBag)
		
		
	}
}
