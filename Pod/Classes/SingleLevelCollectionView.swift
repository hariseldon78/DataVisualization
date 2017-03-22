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
	
	func registerDataCell(_ nib: Either<UINib, UIView.Type>)
}

extension ControllerWithCollectionView where Self:Disposer
{
	func setupRefreshControl(_ invalidateCacheAndReBindData:@escaping (/*atEnd:*/@escaping ()->())->())
	{
		let rc=UIRefreshControl()
		rc.backgroundColor=UIColor.clear
		collectionView.bounces=true
		collectionView.alwaysBounceVertical=true
		collectionView.addSubview(rc)
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
			collectionView.register(nib, forCellWithReuseIdentifier: "cell")
		case .second(let clazz):
			collectionView.register(clazz, forCellWithReuseIdentifier: "cell")
		}
	}
}

public protocol CollectionViewDelegate:UICollectionViewDelegate {
	var collectionView:UICollectionView! {get}
	associatedtype DataViewModel:CollectionViewModel
}


public protocol AutoSingleLevelCollectionView:AutoSingleLevelDataView {
	func setupCollectionView(_ collectionView: UICollectionView,vc:UIViewController)
}

open class AutoSingleLevelCollectionViewManager<
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
	open var collectionView: UICollectionView!
	open var dataExtractor:DataExtractorBase<Data>
	public typealias Data=DataType
	public typealias DataViewModel=DataViewModelType
	open var data:Observable<[Data]> {
		return dataExtractor.data()
			.observeOn(MainScheduler.instance)
//			.subscribeOn(MainScheduler.instance)
			.shareReplayLatestWhileConnected()
	}
	open let 🗑=DisposeBag()
	open let viewModel:DataViewModel
	open var vc:UIViewController!
	var cellSizesCache=[IndexPath:CGSize]()
	
	var onClick:((_ row:Data)->())?=nil
	var clickedObj:Data?

	public required init(viewModel:DataViewModel,dataExtractor:DataExtractorBase<Data>){
		self.viewModel=viewModel
		self.dataExtractor=dataExtractor
		super.init()
	}
	
	open func setupCollectionView(_ collectionView: UICollectionView,vc:UIViewController)
	{
		guard let nib=viewModel.cellNib else {
			DataVisualization.fatalError("No cellNib defined: are you using ConcreteViewModel properly?")
		}
		
		self.vc=vc
		self.collectionView=collectionView
		let dataOrResize=Driver.combineLatest(data.asDriver(onErrorJustReturn: [DataType]()),viewModel.cellResizeEvents.asDriver(onErrorJustReturn: ()),resultSelector:{ $0.0 })
		let cellSizes=dataOrResize.map{ (elements)->[CGSize] in
			return Array(zip(IteratorSequence(IntGenerator()),elements)).map {
				(index,element) in
				let cols=CGFloat(DataViewModel.columns)
				let w=self.collectionView.bounds.size.width
				let hBd=DataViewModel.spacings.horizontalBorder
				let hSp=DataViewModel.spacings.horizontalSpacing
				// expression too complex
				return self.viewModel.cellSize(index, item: element, maxWidth: (w-hBd*2-hSp*(cols-1))/cols)
			}
		}
		collectionView.collectionViewLayout=DynamicCollectionViewLayout(cellSizes:cellSizes.asDriver(onErrorJustReturn:[CGSize.zero]),spacings:DataViewModel.spacings)
		viewModel.cellResizeEvents.onNext()
		
		viewModel.cellResizeEvents.subscribe(onNext: { self.collectionView.collectionViewLayout.invalidateLayout()	}).addDisposableTo(🗑)
		data.subscribe(onNext: {_ in self.collectionView.collectionViewLayout.invalidateLayout() }).addDisposableTo(🗑)
		registerDataCell(nib)
		bindData()
		
		if let Cached=Data.self as? Cached.Type
		{
			setupRefreshControl{ atEnd in
				Cached.invalidateCache()
				
				self.dataExtractor.refresh(hideProgress:true)
				self.data
					.map {_ in return ()}
					.take(1)
					.subscribe(onNext:{
						atEnd()
					})
					.addDisposableTo(self.🗑)
			}
		}
		
		collectionView.delegate=nil
		collectionView.rx.setDelegate(self)
		
		collectionView
			.rx.modelSelected(Data.self)
			.subscribe(onNext: { (obj) in
				self.clickedObj=obj
				self.onClick?(obj)
				collectionView.indexPathsForSelectedItems?.forEach{ (indexPath) in
					collectionView.deselectItem(at: indexPath, animated: true)
				}
		}).addDisposableTo(🗑)
	}

	@discardableResult func bindData()->Observable<Void> {
		data
			.bindTo(collectionView.rx.items(cellIdentifier:"cell")) {
				(index,item,cell)->Void in
				self.viewModel.cellFactory(index, item: item, cell: cell as! DataViewModel.Cell)
				cell.setNeedsUpdateConstraints()
				cell.updateConstraintsIfNeeded()
				
		}.addDisposableTo(🗑)
		
		handleEmpty()
		return data.map{_ in return ()}
	}
	
	func handleEmpty()
	{
		data
			.map { $0.isEmpty }
			.subscribe(
				onNext:{ empty in
					if empty {
						self.collectionView.backgroundView=self.viewModel.viewForEmptyList
					} else {
						self.collectionView.backgroundView=nil
					}
			},
				onError:{ _ in
					self.collectionView.backgroundView=self.viewModel.viewForDataError
			}) .addDisposableTo(🗑)
	}
	
	open func setupOnSelect(_ onSelect:OnSelectBehaviour<Data>)
	{
		func prepareSegue(_ segue:String,presentation:PresentationMode)
		{
			let detailSegue=segue
			onClick={ _ in self.vc.performSegue(withIdentifier: segue, sender: nil) }
			vc.rx_prepareForSegue.subscribe(onNext: { (segue,_) in
				guard let destVC=segue.destination as? UIViewController,
					let identifier=segue.identifier else {return}
				
				if identifier==detailSegue {
					guard var dest=segue.destination as? DetailView
						else {return}
					dest.detailManager.object=self.clickedObj
				}
				}).addDisposableTo(🗑)
		}
		switch onSelect
		{
		case .segue(let name,let presentation):
			prepareSegue(name,presentation: presentation)
			
		case .action(let closure):
			self.onClick=closure
		case .none:
			_=0
		}
	}
	
}
