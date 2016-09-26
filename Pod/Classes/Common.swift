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
	
	func registerDataCell(_ nib: Either<UINib, UIView.Type>)
	func registerSectionCell(_ sectionNib: Either<UINib, UIView.Type>)
}

extension ControllerWithTableView where Self:Disposer
{
	func setupRefreshControl(_ invalidateCacheAndReBindData:@escaping ()->())
	{
		// devo usare un tvc dummy perchè altrimenti RefreshControl si comporta male, il frame non è impostato correttamente.
		let rc=UIRefreshControl()
		let dummyTvc=UITableViewController()
		rc.backgroundColor=UIColor.clear
		vc.addChildViewController(dummyTvc)
		dummyTvc.tableView=tableView
		tableView.bounces=true
		tableView.alwaysBounceVertical=true
		dummyTvc.refreshControl=rc
		rc.rx.controlEvent(UIControlEvents.valueChanged).subscribeNext{ _ in
			invalidateCacheAndReBindData()
			rc.endRefreshing()
			}.addDisposableTo(disposeBag)
	}
	
	func registerDataCell(_ nib: Either<UINib, UIView.Type>)
	{
		switch nib
		{
		case .first(let nib):
			tableView.register(nib, forCellReuseIdentifier: "cell")
		case .second(let clazz):
			tableView.register(clazz, forCellReuseIdentifier: "cell")
		}
	}
	
	func registerSectionCell(_ sectionNib: Either<UINib, UIView.Type>)
	{
		switch sectionNib
		{
		case .first(let nib):
			tableView.register(nib, forHeaderFooterViewReuseIdentifier: "section")
		case .second(let clazz):
			tableView.register(clazz, forHeaderFooterViewReuseIdentifier: "section")
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
