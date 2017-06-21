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

protocol AggregateView {
	func indexPath(at: CGPoint)->IndexPath?
	func cell(at: IndexPath)->UIView?
	func model(at: IndexPath)->Any? // I know, I know..
}

protocol PeekPoppable:class {
	associatedtype Data
	var 🗑:DisposeBag {get}
	var clickedObj:Data? {get set}
	var onClick:((_ row:Data)->())? {get}
	var delegate:PeekPoppableDelegate!/*PeekPopDelegate<Self,Data>!*/ {get set}
	
}
protocol PeekPoppableDelegate: class,UIViewControllerPreviewingDelegate{
	var _onPeek:Any? {get set}
}
class PeekPopDelegate<Manager,Data>:NSObject,UIViewControllerPreviewingDelegate,PeekPoppableDelegate where Manager:PeekPoppable, Manager.Data==Data{
	let manager:Manager
	var _onPeek:Any?
	var onPeek:((Observable<Data>)->(UIViewController?))? {return _onPeek as! ((Observable<Data>)->(UIViewController?))?}
	let aggregateView:AggregateView
	init(manager:Manager,aggregateView:AggregateView){
		self.manager=manager
		self.aggregateView=aggregateView
	}
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		guard let onPeek=onPeek else {return nil}
		if let i=aggregateView.indexPath(at: location) {
			if let cell=aggregateView.cell(at: i)  {
				previewingContext.sourceRect=cell.frame
			}
			if let model=aggregateView.model(at: i), let obj:Data = model as? Data {
				manager.clickedObj=obj
				return onPeek(Observable.just(obj))
			}
		}
		return nil
	}
	
	public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		if let obj=manager.clickedObj {
			manager.onClick?(obj)
		}
		
	}

	
}
extension PeekPoppable {
	func enablePeekPop(vc:UIViewController,aggregateView:AggregateView) {
		self.delegate=PeekPopDelegate(manager: self, aggregateView: aggregateView)
		if vc.traitCollection.forceTouchCapability == .available {
			vc.registerForPreviewing(with: delegate, sourceView: aggregateView as! UIView)
		}
	}
	public func setupPeekPop(onPeek:@escaping (Observable<Data>)->(UIViewController?))
	{
		self.delegate._onPeek=onPeek
	}
	
	public func setupPeekPopDetail(getVc:@escaping ()->UIViewController?)
	{
		self.setupPeekPop{ (data:Observable<Data>) in
			guard let dv=getVc(), var dvc=dv as? DetailView else {return nil}
			data.subscribe(onNext: { d in
				DispatchQueue.main.async {
					dvc.detailManager.object=d
				}
			}).addDisposableTo(self.🗑)
			
			return UINavigationController(rootViewController:dv)
		}
		
	}

}

extension UITableView:AggregateView {
	func indexPath(at point: CGPoint)->IndexPath?
	{
		return indexPathForRow(at: point)
	}
	func cell(at index: IndexPath)->UIView?
	{
		return cellForRow(at: index)
	}
	func model(at index: IndexPath)->Any?
	{
		return try? rx.model(at: index)
	}
}
extension UICollectionView:AggregateView {
	func indexPath(at point: CGPoint)->IndexPath?
	{
		return indexPathForItem(at: point)
	}
	func cell(at index: IndexPath)->UIView?
	{
		return cellForItem(at: index)
	}
	func model(at index: IndexPath)->Any?
	{
		return try? rx.model(at: index)
	}
}

