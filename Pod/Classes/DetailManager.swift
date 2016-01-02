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
public class DetailManager<Data>:DetailManagerType
{
	public init(){}
	let disposeBag=DisposeBag()
	var objObs:Variable<Data>!
	public var object:Any? {didSet{
		guard let w=object as? Data else {fatalError("wrong type passed to detailManager")}
		if objObs==nil { objObs=Variable(w) }
		else { objObs.value=w }
		}
	}
	public typealias Binder=(obj:Observable<Data>,disposeBag:DisposeBag)->()
	public var binder:Binder?
	public func viewDidLoad() {
		let obj=objObs.asObservable().observeOn(MainScheduler.instance)
		binder?(obj:obj,disposeBag:disposeBag)
	}
	
}