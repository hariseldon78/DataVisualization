//
//  DetailManager.swift
//  Pods
//
//  Created by Roberto Previdi on 02/01/16.
//
//

import Foundation
import RxSwift
import RxCocoa

public protocol DetailView {
	var detailManager:DetailManagerType {get set}
}
public protocol DetailManagerType
{
	var object:Any? {get set}
	func viewDidLoad()
}
open class DetailManager<Data>:DetailManagerType
{
	public init(){}
	let disposeBag=DisposeBag()
	var objObs:Variable<Data>!
	open var object:Any? {didSet{
		guard let w=object as? Data else {
			DataVisualization.nonFatalError("wrong type passed to detailManager")
			return
		}
		if objObs==nil { objObs=Variable(w) }
		else { objObs.value=w }
		if viewDidLoadPassed {bind()}
		}
	}
	public typealias Binder=(_ obj:Observable<Data>,_ disposeBag:DisposeBag)->()
	open var binder:Binder?
	var viewDidLoadPassed=false
	open func viewDidLoad() {
		viewDidLoadPassed=true
		if objObs != nil {
			bind()
		}
	}
	func bind(){
		let obj=objObs.asObservable().observeOn(MainScheduler.instance)
		binder?(obj,disposeBag)
	}
	
}
