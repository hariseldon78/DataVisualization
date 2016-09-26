//
//  SearchUtils.swift
//  Pods
//
//  Created by Roberto Previdi on 13/04/16.
//
//

import Foundation
import RxSwift
import RxCocoa
import Cartography

public enum SearchControllerStyle
{
	case searchBarInTableHeader
	case searchBarInNavigationBar
}

// non dovrebbe essere pubblico
protocol Searchable:class,ControllerWithTableView,Disposer
{
	var searchController:UISearchController! {get set}
	func setupSearchController(_ style:SearchControllerStyle)
}
extension UIImage {
	class func imageWithColor(_ color: UIColor) -> UIImage {
		let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
		UIGraphicsBeginImageContext(rect.size)
		let context = UIGraphicsGetCurrentContext()
		
		context?.setFillColor(color.cgColor)
		context?.fill(rect)
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image!
	}
}
class CustomSearchBar: UISearchBar {
	
	override func setShowsCancelButton(_ showsCancelButton: Bool, animated: Bool) {
		super.setShowsCancelButton(false, animated: false)
	}
	open let cancelSubject = PublishSubject<Int>()
	open var rx_cancel: ControlEvent<Void> {
		let source=rx.delegate.observe("searchBarCancelButtonClicked:").map{_ in _=0}
		let events = Observable.of(source,cancelSubject.asObservable().map{_ in  _=0}).merge()
		//			[source, cancelSubject].toObservable().merge()
		return ControlEvent(events: events)
	}
	
	open var rx_textOrCancel: ControlProperty<String> {
		
		func bindingErrorToInterface(_ error: Error) {
			let error = "Binding error to UI: \(error)"
			DataVisualization.nonFatalError(error)
		}
		
		let cancelMeansNoText=rx_cancel.map{""}
		let source:Observable<String>=Observable.of(
			rx.text.asObservable(),
			cancelMeansNoText)
			.merge()
		return ControlProperty(values: source, valueSink: AnyObserver { [weak self] event in
			switch event {
			case .next(let value):
				self?.text = value
			case .error(let error):
				bindingErrorToInterface(error)
			case .completed:
				break
			}
			})
	}
	
}

class CustomSearchController: UISearchController, UISearchBarDelegate {
	
	lazy var _searchBar: CustomSearchBar = {
		[unowned self] in
		let customSearchBar = CustomSearchBar(frame: CGRect.zero)
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
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName:nibNameOrNil,bundle:nibBundleOrNil)
	}
	required override init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
}
extension Searchable
{
	
	/// To be called in viewDidLoad
	func setupSearchController(_ style:SearchControllerStyle)
	{
		searchController=({
			
			let sc=CustomSearchController(searchResultsController: nil)
			switch style{
			case .searchBarInTableHeader:
				sc.hidesNavigationBarDuringPresentation=false
				sc.dimsBackgroundDuringPresentation=false
				sc.searchBar.searchBarStyle=UISearchBarStyle.minimal
				sc.searchBar.backgroundColor=UIColor(white: 1.0, alpha: 0.95)
				sc.searchBar.sizeToFit()
			case .searchBarInNavigationBar:
				sc.hidesNavigationBarDuringPresentation=false
				sc.dimsBackgroundDuringPresentation=false
				sc.searchBar.searchBarStyle=UISearchBarStyle.prominent
				//				sc.searchBar.tintColor=UIColor(white:0.9, alpha:1.0) // non bianco altrimenti non si vede il cursore (influisce sul cursore e sul testo del pulsante cancel)
				sc.searchBar.sizeToFit()
			}
			return sc
			
			}())
		switch style{
		case .searchBarInTableHeader:
			self.tableView.tableHeaderView=self.searchController.searchBar
		case .searchBarInNavigationBar:
			var buttons=self.vc.navigationItem.rightBarButtonItems ?? [UIBarButtonItem]()
			let searchButton=UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.search, target: nil, action: nil)
			searchButton.rx.tap.subscribeNext{
				guard let searchBar=self.searchController.searchBar as? CustomSearchBar else {return}
				if self.vc.navigationItem.titleView==nil
				{
					guard let navBar=self.vc.navigationController?.navigationBar else {return}
					let buttonFrames = navBar.subviews.filter({
						$0 is UIControl
					}).sorted(by: {
						$0.frame.origin.x < $1.frame.origin.x
					}).map({
						$0.convert($0.bounds, to:nil)
					})
					let btnFrame=buttonFrames[buttonFrames.count-1]
					let containerFrame=CGRect(x:0, y:0, width:navBar.frame.size.width, height:btnFrame.size.height)
					let superview=UIView(frame:containerFrame)
					superview.backgroundColor=UIColor.clear
					superview.clipsToBounds=true
					
					//					searchBar.backgroundColor=UIColor.redColor()
					//					searchBar.barTintColor=UIColor.whiteColor()
					var textFieldInsideSearchBar = searchBar.value(forKey: "searchField") as? UITextField
					textFieldInsideSearchBar?.textColor = UIColor.black
					searchBar.tintColor=UIColor.black // colora il cursore e testo cancel
					
					searchBar.backgroundImage=UIImage.imageWithColor(UIColor.clear)
					//					searchBar.showsCancelButton=false
					self.vc.navigationItem.titleView=superview
					superview.addSubview(searchBar)
					// deve stare alla stessa altezza dei pulsanti
					
//					print(NSStringFromCGRect(btnFrame))
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
				self.searchController.isActive=false
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
