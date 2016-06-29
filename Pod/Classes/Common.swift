//
//  ControllerWithTableView.swift
//  Pods
//
//  Created by Roberto Previdi on 29/06/16.
//
//

import Foundation

protocol ControllerWithTableView
{
	var tableView:UITableView! {get}
	var vc:UIViewController! {get}
	
	func registerDataCell(nib: Either<UINib, UIView.Type>)
	func registerSectionCell(sectionNib: Either<UINib, UIView.Type>)
}

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
	
	func registerDataCell(nib: Either<UINib, UIView.Type>)
	{
		switch nib
		{
		case .First(let nib):
			tableView.registerNib(nib, forCellReuseIdentifier: "cell")
		case .Second(let clazz):
			tableView.registerClass(clazz, forCellReuseIdentifier: "cell")
		}
	}
	
	func registerSectionCell(sectionNib: Either<UINib, UIView.Type>)
	{
		switch sectionNib
		{
		case .First(let nib):
			tableView.registerNib(nib, forHeaderFooterViewReuseIdentifier: "section")
		case .Second(let clazz):
			tableView.registerClass(clazz, forHeaderFooterViewReuseIdentifier: "section")
		}
	}
	func setupRowSize()
	{
		tableView.rowHeight=UITableViewAutomaticDimension
		tableView.estimatedRowHeight=50
	}
	func setupSectionSize()
	{
		tableView.sectionHeaderHeight=UITableViewAutomaticDimension
		tableView.estimatedSectionHeaderHeight=50
	}
}

struct PrepareSegueHelper<Data>
{
	
}
