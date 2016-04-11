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
import Cartography

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
	typealias Data:WithApi
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
extension UIImage {
	class func imageWithColor(color: UIColor) -> UIImage {
		let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
		UIGraphicsBeginImageContext(rect.size)
		let context = UIGraphicsGetCurrentContext()
		
		CGContextSetFillColorWithColor(context, color.CGColor)
		CGContextFillRect(context, rect)
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image
	}
}
class CustomSearchBar: UISearchBar {
	
	override func setShowsCancelButton(showsCancelButton: Bool, animated: Bool) {
		super.setShowsCancelButton(false, animated: false)
	}
	public let cancelSubject = PublishSubject<Int>()
	public var rx_cancel: ControlEvent<Void> {
		let source=rx_delegate.observe("searchBarCancelButtonClicked:").map{_ in _=0}
		let events = Observable.of(source,cancelSubject.asObservable().map{_ in  _=0}).merge()
		//			[source, cancelSubject].toObservable().merge()
		return ControlEvent(events: events)
	}
	
	public var rx_textOrCancel: ControlProperty<String> {
		
		func bindingErrorToInterface(error: ErrorType) {
			let error = "Binding error to UI: \(error)"
			#if DEBUG
				fatalError(error)
			#else
				print(error)
			#endif
		}
		
		let cancelMeansNoText=rx_cancel.map{""}
		let source:Observable<String>=Observable.of(
			rx_text.asObservable(),
			cancelMeansNoText)
			.merge()
		return ControlProperty(values: source, valueSink: AnyObserver { [weak self] event in
			switch event {
			case .Next(let value):
				self?.text = value
			case .Error(let error):
				bindingErrorToInterface(error)
			case .Completed:
				break
			}
			})
	}
	
}

class CustomSearchController: UISearchController, UISearchBarDelegate {
	
	lazy var _searchBar: CustomSearchBar = {
		[unowned self] in
		let customSearchBar = CustomSearchBar(frame: CGRectZero)
		customSearchBar.delegate = self
		return customSearchBar
		}()
	
	override var searchBar: UISearchBar {
		get {
			return _searchBar
		}
	}
	override init(searchResultsController: UIViewController?) {
		super.init(searchResultsController: searchResultsController)
	}
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName:nibNameOrNil,bundle:nibBundleOrNil)
	}
	required override init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
}
extension Searchable
{
	
	/// To be called in viewDidLoad
	func setupSearchController(style:SearchControllerStyle)
	{
		searchController=({
			
			let sc=CustomSearchController(searchResultsController: nil)
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
				//				sc.searchBar.tintColor=UIColor(white:0.9, alpha:1.0) // non bianco altrimenti non si vede il cursore (influisce sul cursore e sul testo del pulsante cancel)
				sc.searchBar.sizeToFit()
			}
			return sc
			
			}())
		switch style{
		case .SearchBarInTableHeader:
			self.tableView.tableHeaderView=self.searchController.searchBar
		case .SearchBarInNavigationBar:
			var buttons=self.vc.navigationItem.rightBarButtonItems ?? [UIBarButtonItem]()
			let searchButton=UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: nil, action: nil)
			searchButton.rx_tap.subscribeNext{
				guard let searchBar=self.searchController.searchBar as? CustomSearchBar else {return}
				if self.vc.navigationItem.titleView==nil
				{
					guard let navBar=self.vc.navigationController?.navigationBar else {return}
					let buttonFrames = navBar.subviews.filter({
						$0 is UIControl
					}).sort({
						$0.frame.origin.x < $1.frame.origin.x
					}).map({
						$0.convertRect($0.bounds, toView:nil)
					})
					let btnFrame=buttonFrames[buttonFrames.count-1]
					let containerFrame=CGRectMake(0, 0, navBar.frame.size.width, btnFrame.size.height)
					let superview=UIView(frame:containerFrame)
					superview.backgroundColor=UIColor.clearColor()
					superview.clipsToBounds=true
					
					//					searchBar.backgroundColor=UIColor.redColor()
					//					searchBar.barTintColor=UIColor.whiteColor()
					var textFieldInsideSearchBar = searchBar.valueForKey("searchField") as? UITextField
					textFieldInsideSearchBar?.textColor = UIColor.blackColor()
					searchBar.tintColor=UIColor.blackColor() // colora il cursore e testo cancel
					
					searchBar.backgroundImage=UIImage.imageWithColor(UIColor.clearColor())
					//					searchBar.showsCancelButton=false
					self.vc.navigationItem.titleView=superview
					superview.addSubview(searchBar)
					// deve stare alla stessa altezza dei pulsanti
					
					print(NSStringFromCGRect(btnFrame))
					constrain(searchBar){
						//						$0.top 		== $0.superview!.top+btnFrame.origin.y
						//						$0.height 	== btnFrame.size.height
						$0.top 		== $0.superview!.top
						$0.bottom 	== $0.superview!.bottom
						$0.leading	== $0.superview!.leading
						$0.trailing	== $0.superview!.trailing
					}
					
				}
				else
				{
					searchBar.cancelSubject.onNext(0)
					searchBar.text=""
					self.vc.navigationItem.titleView=nil
				}
				}.addDisposableTo(self.disposeBag)
			buttons.append(searchButton)
			self.vc.navigationItem.rightBarButtonItems=buttons
			self.vc.definesPresentationContext=true
		}
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
class TableViewDelegate:NSObject,UITableViewDelegate{
	func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
		return UITableViewCellEditingStyle.None
	}
}

public class AutoSingleLevelTableViewManager<
	DataType,
	DataViewModel
	where
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
	var tableViewDelegate=TableViewDelegate()
	
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
		dump(tableView)
		tableView.rx_setDelegate(tableViewDelegate)
		
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

public class AutoSearchableSingleLevelTableViewManager<DataType,DataViewModel where DataType:WithApi,DataViewModel:ViewModel,DataViewModel.Data==DataType>:AutoSingleLevelTableViewManager<DataType,DataViewModel>,Searchable
{
	public var searchController:UISearchController!
	public typealias FilteringClosure=(d:DataType,s:String)->Bool
	public var filteringClosure:FilteringClosure
	let searchStyle:SearchControllerStyle
	public var search:Observable<String> {
		guard let searchBar=searchController.searchBar as? CustomSearchBar else {fatalError()}
		return searchBar.rx_textOrCancel.asObservable()
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



