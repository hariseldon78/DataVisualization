//
//  ControllerWithTableView.swift
//  Pods
//
//  Created by Roberto Previdi on 29/06/16.
//
//

import Foundation
import RxSwift

protocol ControllerWithTableView
{
	var tableView:UITableView! {get}
	var vc:UIViewController! {get}
	
	func registerDataCell(_ nib: Either<UINib, UIView.Type>)
	func registerSectionCell(_ sectionNib: Either<UINib, UIView.Type>)
}
public let DataRetrieveQueue:OperationQueue={
	let opQ=OperationQueue()
	opQ.qualityOfService = .userInitiated
	return opQ
}()
public let DataRetrieveScheduler=OperationQueueScheduler(operationQueue: DataRetrieveQueue)
extension ControllerWithTableView where Self:Disposer
{
	func setupRefreshControl(_ invalidateCacheAndReBindData:@escaping (/*atEnd:*/@escaping ()->())->())
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
		rc.rx.controlEvent(UIControlEvents.valueChanged).subscribe(onNext:{ _ in
			invalidateCacheAndReBindData() {
				rc.endRefreshing()
			}
			}).addDisposableTo(🗑)
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
