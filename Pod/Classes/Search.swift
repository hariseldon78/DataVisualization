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
	case SearchBarInTableHeader
	case SearchBarInNavigationBar
}

// non dovrebbe essere pubblico
protocol Searchable:class,ControllerWithTableView,Disposer
{
	var searchController:UISearchController! {get set}
	func setupSearchController(style:SearchControllerStyle)
}
extension UIImage {
	class func imageWithColor(color: UIColor) -> UIImage {
		let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
		UIGraphicsBeginImageContext(rect.size)
		let context = UIGraphicsGetCurrentContext()
		
		CGContextSetFillColorWithColor(context, color.CGColor)
		CGContextFillRect(context, rect)
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image
	}
}
class CustomSearchBar: UISearchBar {
	
	override func setShowsCancelButton(showsCancelButton: Bool, animated: Bool) {
		super.setShowsCancelButton(false, animated: false)
	}
	public let cancelSubject = PublishSubject<Int>()
	public var rx_cancel: ControlEvent<Void> {
		let source=rx_delegate.observe("searchBarCancelButtonClicked:").map{_ in _=0}
		let events = Observable.of(source,cancelSubject.asObservable().map{_ in  _=0}).merge()
		//			[source, cancelSubject].toObservable().merge()
		return ControlEvent(events: events)
	}
	
	public var rx_textOrCancel: ControlProperty<String> {
		
		func bindingErrorToInterface(error: ErrorType) {
			let error = "Binding error to UI: \(error)"
			#if DEBUG
				fatalError(error)
			#else
				print(error)
			#endif
		}
		
		let cancelMeansNoText=rx_cancel.map{""}
		let source:Observable<String>=Observable.of(
			rx_text.asObservable(),
			cancelMeansNoText)
			.merge()
		return ControlProperty(values: source, valueSink: AnyObserver { [weak self] event in
			switch event {
			case .Next(let value):
				self?.text = value
			case .Error(let error):
				bindingErrorToInterface(error)
			case .Completed:
				break
			}
			})
	}
	
}

class CustomSearchController: UISearchController, UISearchBarDelegate {
	
	lazy var _searchBar: CustomSearchBar = {
		[unowned self] in
		let customSearchBar = CustomSearchBar(frame: CGRectZero)
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
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName:nibNameOrNil,bundle:nibBundleOrNil)
	}
	required override init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
}
extension Searchable
{
	
	/// To be called in viewDidLoad
	func setupSearchController(style:SearchControllerStyle)
	{
		searchController=({
			
			let sc=CustomSearchController(searchResultsController: nil)
			switch style{
			case .SearchBarInTableHeader:
				sc.hidesNavigationBarDuringPresentation=false
				sc.dimsBackgroundDuringPresentation=false
				sc.searchBar.searchBarStyle=UISearchBarStyle.Minimal
				sc.searchBar.backgroundColor=UIColor(white: 1.0, alpha: 0.95)
				sc.searchBar.sizeToFit()
			case .SearchBarInNavigationBar:
				sc.hidesNavigationBarDuringPresentation=false
				sc.dimsBackgroundDuringPresentation=false
				sc.searchBar.searchBarStyle=UISearchBarStyle.Prominent
				//				sc.searchBar.tintColor=UIColor(white:0.9, alpha:1.0) // non bianco altrimenti non si vede il cursore (influisce sul cursore e sul testo del pulsante cancel)
				sc.searchBar.sizeToFit()
			}
			return sc
			
			}())
		switch style{
		case .SearchBarInTableHeader:
			self.tableView.tableHeaderView=self.searchController.searchBar
		case .SearchBarInNavigationBar:
			var buttons=self.vc.navigationItem.rightBarButtonItems ?? [UIBarButtonItem]()
			let searchButton=UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Search, target: nil, action: nil)
			searchButton.rx_tap.subscribeNext{
				guard let searchBar=self.searchController.searchBar as? CustomSearchBar else {return}
				if self.vc.navigationItem.titleView==nil
				{
					guard let navBar=self.vc.navigationController?.navigationBar else {return}
					let buttonFrames = navBar.subviews.filter({
						$0 is UIControl
					}).sort({
						$0.frame.origin.x < $1.frame.origin.x
					}).map({
						$0.convertRect($0.bounds, toView:nil)
					})
					let btnFrame=buttonFrames[buttonFrames.count-1]
					let containerFrame=CGRectMake(0, 0, navBar.frame.size.width, btnFrame.size.height)
					let superview=UIView(frame:containerFrame)
					superview.backgroundColor=UIColor.clearColor()
					superview.clipsToBounds=true
					
					//					searchBar.backgroundColor=UIColor.redColor()
					//					searchBar.barTintColor=UIColor.whiteColor()
					var textFieldInsideSearchBar = searchBar.valueForKey("searchField") as? UITextField
					textFieldInsideSearchBar?.textColor = UIColor.blackColor()
					searchBar.tintColor=UIColor.blackColor() // colora il cursore e testo cancel
					
					searchBar.backgroundImage=UIImage.imageWithColor(UIColor.clearColor())
					//					searchBar.showsCancelButton=false
					self.vc.navigationItem.titleView=superview
					superview.addSubview(searchBar)
					// deve stare alla stessa altezza dei pulsanti
					
					print(NSStringFromCGRect(btnFrame))
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
				self.searchController.active=false
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