//
//  SingleLevelCollectionView.swift
//  Pods
//
//  Created by Roberto Previdi on 21/06/16.
//
//

import Foundation
import RxSwift
import RxCocoa
import Cartography


// duplico parecchio codice da SingleLevelTableView.swift; 
// TODO: unificare più possibile con qualche protocols. vedi ad esempio http://basememara.com/protocol-oriented-tableview-collectionview/

protocol ControllerWithCollectionView
{
	var collectionView:UICollectionView! {get}
	var vc:UIViewController! {get}
	
	func registerDataCell(nib: Either<UINib, UIView.Type>)
}

extension ControllerWithCollectionView where Self:Disposer
{
	func setupRefreshControl(invalidateCacheAndReBindData:()->())
	{
//		// devo usare un tvc dummy perchè altrimenti RefreshControl si comporta male, il frame non è impostato correttamente.
//		let rc=UIRefreshControl()
//		let dummyTvc=UITableViewController()
//		rc.backgroundColor=UIColor.clearColor()
//		vc.addChildViewController(dummyTvc)
//		dummyTvc.tableView=tableView
//		tableView.bounces=true
//		tableView.alwaysBounceVertical=true
//		dummyTvc.refreshControl=rc
//		rc.rx_controlEvent(UIControlEvents.ValueChanged).subscribeNext{ _ in
//			invalidateCacheAndReBindData()
//			rc.endRefreshing()
//			}.addDisposableTo(disposeBag)
	}
	
	func registerDataCell(nib: Either<UINib, UIView.Type>)
	{
		switch nib
		{
		case .First(let nib):
			collectionView.registerNib(nib, forCellWithReuseIdentifier: "cell")
		case .Second(let clazz):
			collectionView.registerClass(clazz, forCellWithReuseIdentifier: "cell")
		}
	}
}

public protocol AutoSingleLevelCollectionView:AutoSingleLevelDataView {
	func setupCollectionView(collectionView: UICollectionView,vc:UIViewController)
}

public class AutoSingleLevelCollectionViewManager<
	DataType,
	DataViewModel
	where
	DataType:WithApi,
	DataViewModel:ViewModel,
	DataViewModel.Data==DataType>
	
	:	NSObject,
	AutoSingleLevelCollectionView,
	ControllerWithCollectionView
{
	public var collectionView: UICollectionView!
	public typealias Data=DataType
	public var data:Observable<[Data]> {
		return DataType.api(collectionView)
			.subscribeOn(backgroundScheduler)
			.map {$0}
			.shareReplayLatestWhileConnected()
			.observeOn(MainScheduler.instance)
	}
	public let disposeBag=DisposeBag()
	public var dataBindDisposeBag=DisposeBag()
	public let viewModel:DataViewModel
	public var vc:UIViewController!
	
	public required init(viewModel:DataViewModel){
		self.viewModel=viewModel
	}
	
	public func setupCollectionView(collectionView: UICollectionView,vc:UIViewController)
	{
		guard let nib=viewModel.cellNib else {
			fatalError("No cellNib defined: are you using ConcreteViewModel properly?")
		}
		
		self.vc=vc
		self.collectionView=collectionView
		
//		collectionView.rx_setDelegate(self)
		
		registerDataCell(nib)
		bindData()
		
	}
	
	func bindData()
	{
		data
			.bindTo(collectionView.rx_itemsWithCellIdentifier("cell")) {
				(index,item,cell)->Void in
				self.viewModel.cellFactory(index, item: item, cell: cell as! DataViewModel.Cell)
				cell.setNeedsUpdateConstraints()
				cell.updateConstraintsIfNeeded()
				
				
		}.addDisposableTo(dataBindDisposeBag)
		
		
		
	}
}