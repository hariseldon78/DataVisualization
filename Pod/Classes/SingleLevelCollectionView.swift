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

public protocol CollectionViewDelegate:UICollectionViewDelegate/*,UICollectionViewDelegateFlowLayout*/
{
	var collectionView:UICollectionView! {get}
	typealias DataViewModel:CollectionViewModel
//	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
}
//public extension CollectionViewDelegate
//{
//	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
//		// Set up desired width
//		let cols=DataViewModel.columns
//		let targetWidth = (collectionView.bounds.width - 2*DataViewModel.horizontalBorder - CGFloat(cols-1)*DataViewModel.horizontalSpacing) / CGFloat(cols)
//
//		let cell=collectionView.cellForItemAtIndexPath(indexPath)!
//		
//		// Cell's size is determined in nib file, need to set it's width (in this case), and inside, use this cell's width to set label's preferredMaxLayoutWidth, thus, height can be determined, this size will be returned for real cell initialization
//		cell.bounds = CGRectMake(0, 0, targetWidth, cell.bounds.height)
//		cell.contentView.bounds = cell.bounds
//		
//		// Layout subviews, this will let labels on this cell to set preferredMaxLayoutWidth
//		cell.setNeedsLayout()
//		cell.layoutIfNeeded()
//		
//		var size = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
//		// Still need to force the width, since width can be smalled due to break mode of labels
//		size.width = targetWidth
//		return size
//		
//	}
//}

public protocol AutoSingleLevelCollectionView:AutoSingleLevelDataView {
	func setupCollectionView(collectionView: UICollectionView,vc:UIViewController)
}

public class AutoSingleLevelCollectionViewManager<
	DataType,
	DataViewModelType
	where
	DataViewModelType:CollectionViewModel,
	DataViewModelType.Data==DataType>
	
	:	NSObject,
	AutoSingleLevelCollectionView,
	CollectionViewDelegate,
	ControllerWithCollectionView
{
	public var collectionView: UICollectionView!
	public var dataExtractor:DataExtractorBase<Data>
	public typealias Data=DataType
	public typealias DataViewModel=DataViewModelType
	public var data:Observable<[Data]> {
		return dataExtractor.data()
			.observeOn(MainScheduler.instance)
			.subscribeOn(MainScheduler.instance)
	}
	public let disposeBag=DisposeBag()
	public var dataBindDisposeBag=DisposeBag()
	public let viewModel:DataViewModel
	public var vc:UIViewController!
	var cellSizesCache=[NSIndexPath:CGSize]()
	
	var onClick:((row:Data)->())?=nil
	var clickedObj:Data?

	public required init(viewModel:DataViewModel,dataExtractor:DataExtractorBase<Data>){
		self.viewModel=viewModel
		self.dataExtractor=dataExtractor
		super.init()
		data.debug("data")
	}
	
	public func setupCollectionView(collectionView: UICollectionView,vc:UIViewController)
	{
		guard let nib=viewModel.cellNib else {
			DataVisualization.fatalError("No cellNib defined: are you using ConcreteViewModel properly?")
		}
		
		self.vc=vc
		self.collectionView=collectionView
		let dataOrResize=Driver.combineLatest(data.asDriver(onErrorJustReturn: [DataType]()),viewModel.cellResizeEvents.asDriver(onErrorJustReturn: ()),resultSelector:{ $0.0 })
		let cellSizes=dataOrResize.map{ (elements)->[CGSize] in
			return Array(zip(GeneratorSequence(IntGenerator()),elements)).map {
				(index,element) in
				let cols=CGFloat(DataViewModel.columns)
				let w=self.collectionView.bounds.size.width
				let hBd=DataViewModel.spacings.horizontalBorder
				let hSp=DataViewModel.spacings.horizontalSpacing
				// expression too complex
				return self.viewModel.cellSize(index, item: element, maxWidth: (w-hBd*2-hSp*(cols-1))/cols)
			}
		}
		cellSizes.debug("cellSizes")
		collectionView.collectionViewLayout=DynamicCollectionViewLayout(cellSizes:cellSizes.asDriver(onErrorJustReturn:[CGSizeZero]),spacings:DataViewModel.spacings)
		viewModel.cellResizeEvents.onNext()
		
		viewModel.cellResizeEvents.subscribeNext { self.collectionView.collectionViewLayout.invalidateLayout()	}.addDisposableTo(disposeBag)
		data.subscribeNext {_ in self.collectionView.collectionViewLayout.invalidateLayout() }.addDisposableTo(disposeBag)
		registerDataCell(nib)
		bindData()
		
		collectionView.delegate=nil
		collectionView.rx_setDelegate(self)
		
		collectionView
			.rx_modelSelected(Data.self)
			.subscribeNext { (obj) in
				self.clickedObj=obj
				self.onClick?(row:obj)
				collectionView.indexPathsForSelectedItems()?.forEach{ (indexPath) in
					collectionView.deselectItemAtIndexPath(indexPath, animated: true)
				}
		}.addDisposableTo(disposeBag)
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
		
		handleEmpty()
	}
	
	func handleEmpty()
	{
		data
			.map { $0.isEmpty }
			.subscribeNext{ empty in
				if empty {
					self.collectionView.backgroundView=self.viewModel.viewForEmptyList
				} else {
					self.collectionView.backgroundView=nil
				}
		}.addDisposableTo(dataBindDisposeBag)
	}
	
	public func setupOnSelect(onSelect:OnSelectBehaviour<Data>)
	{
		func prepareSegue(segue:String,presentation:PresentationMode)
		{
			let detailSegue=segue
			onClick={ _ in self.vc.performSegueWithIdentifier(segue, sender: nil) }
			vc.rx_prepareForSegue.subscribeNext { (segue,_) in
				guard let destVC=segue.destinationViewController as? UIViewController,
					let identifier=segue.identifier else {return}
				
				if identifier==detailSegue {
					guard var dest=segue.destinationViewController as? DetailView
						else {return}
					dest.detailManager.object=self.clickedObj
				}
				}.addDisposableTo(disposeBag)
		}
		switch onSelect
		{
		case .Segue(let name,let presentation):
			prepareSegue(name,presentation: presentation)
			
		case .Action(let closure):
			self.onClick=closure
		}
	}
	
}