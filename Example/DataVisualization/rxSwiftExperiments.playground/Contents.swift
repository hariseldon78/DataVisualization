//: Playground - noun: a place where people can play

import RxSwift

let obs=RxSwift.Observable.interval(1)

obs.subscribe { x in
	print(x)
}