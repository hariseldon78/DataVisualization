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

public protocol TableViewManager
{
	var vc:UIViewController! {get}
	var tableView:UITableView! {get}
}

public protocol AutoSingleLevelTableView:Disposer {
	typealias Data:Visualizable,WithApi
	
	var viewModel:ViewModel {get}
	var data:Observable<[Data]> {get}
	func setupTableView(tableView:UITableView,vc:UIViewController)
}

protocol SearchableViewController:UISearchBarDelegate,TableViewManager,UISearchResultsUpdating
{
	var searchController:UISearchController! {get set}
	var isSearching:Bool {get}
	func setupSearchController()
	func tearDownSearchController()
	
}

extension SearchableViewController
{
	/// To be called in viewDidLoad
	func setupSearchController()
	{
		searchController=({
			let sc=UISearchController(searchResultsController: nil)
			sc.searchResultsUpdater=self
			sc.hidesNavigationBarDuringPresentation=false
			sc.dimsBackgroundDuringPresentation=false
			sc.searchBar.searchBarStyle=UISearchBarStyle.Minimal
			sc.searchBar.sizeToFit()
			sc.searchBar.delegate=self
			return sc
			}())
	}
	
	var isSearching:Bool {
		return (searchController.searchBar.text ?? "") != ""
	}
	
	/// To be called in viewWillAppear
	func showSearchController()
	{
		tableView.tableHeaderView=searchController.searchBar
	}
	/// To be called in viewWillDisappear
	func unshowSearchController()
	{
		searchController.active=false
		searchController.searchBar.endEditing(true)
		if isSearching
		{
			// senno si comportava male...
			searchController.searchBar.removeFromSuperview()
		}
	}
	
}

public class AutoSingleLevelTableViewManager<DataType where DataType:Visualizable,DataType:WithApi>:AutoSingleLevelTableView
{
	public typealias Data=DataType
	public let data=Data.api()
	public let disposeBag=DisposeBag()
	public var viewModel=Data.defaultViewModel()
	var vc:UIViewController!
	var tableView:UITableView!

	var onClick:((row:Data)->())?=nil
	var clickedObj:Data?
	
	public init(){}
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
		vc.rx_prepareForSegue.subscribeNext { (segue,_) in
			guard var dest=segue.destinationViewController as? DetailView,
				let identifier=segue.identifier,
				let detailSegue=self.detailSegue else {return}
			if identifier==detailSegue
			{
				dest.detailManager.object=self.clickedObj
			}
		}.addDisposableTo(disposeBag)
	}

	
}





