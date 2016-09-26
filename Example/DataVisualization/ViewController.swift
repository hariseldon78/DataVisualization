//
//  ViewController.swift
//  DataVisualization
//
//  Created by Roberto Previdi on 12/27/2015.
//  Copyright (c) 2015 Roberto Previdi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import DataVisualization

class PlainViewController:UIViewController
{
	@IBOutlet weak var tableView: UITableView!

	var tvManager:AutoSearchableSingleLevelTableViewManager<Worker,Worker.DefaultViewModel>!
	let dataExtractor=ApiExtractor<Worker>(apiParams:["name":"ApiParams" as AnyObject,"salary":Double(4000.0) as AnyObject,"department":UInt(8) as AnyObject])
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager=AutoSearchableSingleLevelTableViewManager(
			viewModel: Worker.defaultViewModel(),
			filteringClosure: { (d:Worker, s:String) -> Bool in
				return d.name.localizedUppercase.contains(s.localizedUppercase)
			},
			dataExtractor: dataExtractor)
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupOnSelect(.detail,.segue(name:"detail",presentation:.push))
	}
}

struct StaticData{
	let s:String
	typealias DefaultViewModel=ConcreteViewModel<StaticData,TitleCell>
	static func defaultViewModel() -> DefaultViewModel {
		return DefaultViewModel(cellName: "TitleCell") { (index, item, cell) in
			cell.title.text=item.s
		}
	}
}
class NoApiViewController:UIViewController
{
	@IBOutlet weak var tableView: UITableView!
	let staticList=[StaticData(s:"ciccio"),StaticData(s:"pasticcio"),StaticData(s:"gigino")]
	var tvManager:AutoSingleLevelTableViewManager<StaticData,StaticData.DefaultViewModel>!
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager=AutoSingleLevelTableViewManager(
			viewModel: StaticData.defaultViewModel(),
			dataExtractor: StaticExtractor(source:Observable.just(staticList)))
		tvManager.setupTableView(tableView,vc:self)
	}
}

class PlainCollectionViewController:UIViewController
{
	let 🗑=DisposeBag()
	@IBOutlet weak var collectionView: UICollectionView!
	var tvManager=AutoSingleLevelCollectionViewManager (viewModel: Worker.defaultCollectionViewModel(),dataExtractor:ApiExtractor())
	
	override func viewDidLoad() {
		super.viewDidLoad()

		tvManager.setupCollectionView( collectionView,vc:self)
		tvManager.setupOnSelect(.segue(name:"detail",presentation:.push))
	}
}

class EmptyCollectionViewController:UIViewController
{
	let 🗑=DisposeBag()
	@IBOutlet weak var collectionView: UICollectionView!
	var tvManager=AutoSingleLevelCollectionViewManager (viewModel: Worker.defaultCollectionViewModel(),dataExtractor:StaticExtractor(source: Observable.just([Worker]())))
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tvManager.setupCollectionView( collectionView,vc:self)
		tvManager.setupOnSelect(.segue(name:"detail",presentation:.push))
	}
}


class StaticViewController:UIViewController
{
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet var staticHeaderView: UIView!
	var tvManager=AutoSearchableSingleLevelTableViewManager (viewModel: Worker.defaultViewModel(), filteringClosure: { (d:Worker, s:String) -> Bool in
		return d.name.localizedUppercase.contains(s.localizedUppercase)
	},dataExtractor:ApiExtractor<Worker>())
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupOnSelect(.info,.segue(name:"detail",presentation:.push))
	}
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		tableView.tableHeaderView=staticHeaderView
		
	}
}

class NoStoryboardViewController:UIViewController
{
	@IBOutlet weak var tableView: UITableView!
	var tvManager=AutoSearchableSingleLevelTableViewManager (viewModel: Worker.defaultViewModel(), filteringClosure: { (d:Worker, s:String) -> Bool in
		return d.name.localizedUppercase.contains(s.localizedUppercase)
	},dataExtractor:ApiExtractor())
	init(){
		super.init(nibName:"NibVC",bundle:Bundle.main)
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder:aDecoder)
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
	}
}

class PlainNoDetViewController:UIViewController
{
	
	@IBOutlet weak var tableView: UITableView!
	var tvManager=AutoSingleLevelTableViewManager(viewModel: Worker.defaultViewModel(),dataExtractor:ApiExtractor())
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupOnSelect(.detail,.action(action: { (d:Worker) -> () in
			dump(d)
			let vc=NoStoryboardViewController()
			self.present(vc, animated: true, completion: nil)
		}))
	}
}
class FunkyViewController:UIViewController {
	@IBOutlet weak var tableView: UITableView!
	typealias DataViewModel=ConcreteViewModel<Worker,FunkyCell>
	let tvManager=AutoSingleLevelTableViewManager(viewModel: DataViewModel(cellName: "FunkyCell") {
		(index:Int, item, cell:DataViewModel.Cell) -> Void in
		cell.title.text=item.name
		cell.subtitle.text="salary: €\(item.salary)"
		},dataExtractor:ApiExtractor())
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupOnSelect(.detail,.segue(name:"detail",presentation:.push))
	}

}

class PlainSectionedViewController:UIViewController {
	@IBOutlet weak var tableView: UITableView!
	let tvManager=AutoSectionedTableViewManager<Worker,Worker.DefaultViewModel,Department,Department.DefaultSectionViewModel,WorkerSectioner>(
		elementViewModel:Worker.defaultViewModel(),sectionViewModel:Department.defaultSectionViewModel(),sectioner:WorkerSectioner())
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupDataOnSelect(.info,.segue(name:"workerDetail",presentation:.push))
		tvManager.setupSectionOnSelect(.segue(name:"departmentDetail",presentation:.push))
	}
}


class SearchSectionedViewController:UIViewController {
	var disposeBag=DisposeBag()
	@IBOutlet weak var tableView: UITableView!
	let tvManager=AutoSearchableSectionedTableViewManager(
		elementViewModel: Worker.defaultViewModel(),
		sectionViewModel: Department.defaultSectionViewModel(),
		sectioner: CollapsableSectioner(original:WorkerSectioner()),
		dataFilteringClosure: { (d, s) -> Bool in
			return d.name.localizedUppercase.contains(s.localizedUppercase)
		},
		sectionFilteringClosure: { (d, s) -> Bool in
			return d.name.localizedUppercase.contains(s.localizedUppercase)
	})
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupDataOnSelect(.detail,.sectionSegue(name:"departmentDetail",presentation:.push))
		tvManager.setupSectionOnSelect(OnSelectBehaviour<Department>.action(action: { (d) in
			// TODO: creare una behaviouraction ad hoc, o almeno un methodo in CollapsableSectionerProtocol
			if let s=self.tvManager.sectioner.selectedSection.value , s==d
			{
				self.tvManager.sectioner.selectedSection.value=nil
			}
			else
			{
				self.tvManager.sectioner.selectedSection.value=d
			}
		}))
		tvManager.search.asObservable()
			.map{!$0.isEmpty}
			.distinctUntilChanged()
			.subscribe(onNext: {
				print("showAll=\($0)")
				self.tvManager.sectioner.showAll.value=$0
		}).addDisposableTo(disposeBag)
		
		
	}
}

class SearchSectionedFunkyViewController:UIViewController {
	var disposeBag=DisposeBag()
	@IBOutlet weak var tableView: UITableView!
	
	typealias DataViewModel=ConcreteViewModel<Worker,FunkyCell>

	let tvManager=AutoSearchableSectionedTableViewManager(
		elementViewModel: DataViewModel(cellName: "FunkyCell") {
			(index:Int, item, cell:DataViewModel.Cell) -> Void in
			cell.title.text=item.name
			cell.subtitle.text="salary: €\(item.salary)"
		},
		sectionViewModel: Department.defaultSectionViewModel(),
		sectioner: CollapsableSectioner(original:WorkerSectioner()),
		dataFilteringClosure: { (d, s) -> Bool in
			return d.name.localizedUppercase.contains(s.localizedUppercase)
		},
		sectionFilteringClosure: { (d, s) -> Bool in
			return d.name.localizedUppercase.contains(s.localizedUppercase)
	})
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tvManager.setupTableView(tableView,vc:self)
		tvManager.setupDataOnSelect(.info,.sectionSegue(name:"departmentDetail",presentation:.push))
		tvManager.setupSectionOnSelect(OnSelectBehaviour<Department>.action(action: { (d) in
			// TODO: creare una behaviouraction ad hoc, o almeno un methodo in CollapsableSectionerProtocol
			if let s=self.tvManager.sectioner.selectedSection.value , s==d
			{
				self.tvManager.sectioner.selectedSection.value=nil
			}
			else
			{
				self.tvManager.sectioner.selectedSection.value=d
			}
		}))
		tvManager.search.asObservable()
			.map{!$0.isEmpty}
			.distinctUntilChanged()
			.subscribe(onNext: {
				print("showAll=\($0)")
				self.tvManager.sectioner.showAll.value=$0
			}).addDisposableTo(disposeBag)
		
		
	}
}
class WorkerDetail1:UIViewController,DetailView
{
	@IBOutlet weak var label1: UILabel!
	@IBOutlet weak var label2: UILabel!
	@IBOutlet weak var label3: UILabel!
	
	var detailManager:DetailManagerType=DetailManager<Worker>()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		(detailManager as! DetailManager<Worker>).binder={ (obj:Observable<Worker>, disposeBag:DisposeBag) -> () in
			obj.map { $0.name }.bindTo(self.label1.rx.text).addDisposableTo(disposeBag)
			obj.map { "salary: €\($0.salary)" }.bindTo(self.label2.rx.text).addDisposableTo(disposeBag)
			obj.map { "dep: \($0.departmentId)" }.bindTo(self.label3.rx.text).addDisposableTo(disposeBag)
		}
		detailManager.viewDidLoad()
	}
}

class WorkerDetail2:UIViewController,DetailView
{
	@IBOutlet weak var label1: UILabel!
	@IBOutlet weak var slider1: UISlider!
	
	var detailManager:DetailManagerType=DetailManager<Worker>()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		(detailManager as! DetailManager<Worker>).binder={ (obj:Observable<Worker>, disposeBag:DisposeBag) -> () in
			obj.map { $0.name }.bindTo(self.label1.rx.text).addDisposableTo(disposeBag)
			obj.map { Float($0.salary) }.bindTo(self.slider1.rx.value).addDisposableTo(disposeBag)
		}
		detailManager.viewDidLoad()

	}
	
}

class DepartmentDetail1:UIViewController,DetailView
{
	@IBOutlet weak var label1: UILabel!
	@IBOutlet weak var label2: UILabel!
	
	var detailManager:DetailManagerType=DetailManager<Department>()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		(detailManager as! DetailManager<Department>).binder={ (obj:Observable<Department>, disposeBag:DisposeBag) -> () in
			obj.map { $0.name }.bindTo(self.label1.rx.text).addDisposableTo(disposeBag)
			obj.map { "\($0.id)" }.bindTo(self.label2.rx.text).addDisposableTo(disposeBag)
		}
		detailManager.viewDidLoad()
	}
}





