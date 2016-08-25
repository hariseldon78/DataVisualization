//
//  CacheTests.swift
//  DataVisualization
//
//  Created by Roberto Previdi on 25/08/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import DataVisualization

class CacheSpec: QuickSpec {
	override func spec() {
		var callsCount=0
		func valueSource(index:Int)->Int {
			callsCount+=1
			return index
		}
		
		describe("the cache") {
			var cache:CachedSequence<Int>=CachedSequence<Int>(calculateValue: valueSource,dummyValue: 0)
			beforeEach {
				cache=CachedSequence<Int>(calculateValue: valueSource,dummyValue: 0)
				callsCount=0
			}
			it("can calculate values") {
				expect(cache.get(5)) == 5
				expect(callsCount) == 1
				expect(cache.get(4)) == 4
				expect(callsCount) == 2
			}
			
			it("caches the calculate values") {
				expect(cache.get(5)) == 5
				expect(callsCount) == 1
				expect(cache.get(5)) == 5
				expect(callsCount) == 1
			}
			
			it("recalculate on invalidation") {
				expect(cache.get(5)) == 5
				expect(callsCount) == 1
				cache.invalidate(5)
				expect(cache.get(5)) == 5
				expect(callsCount) == 2
			}

			it("can invalidate ranges") {
				expect(cache.get(5)) == 5
				expect(callsCount) == 1
				cache.invalidate(3..<10)
				expect(cache.get(5)) == 5
				expect(callsCount) == 2
				expect(cache.get(4)) == 4
				expect(callsCount) == 3
			}

			it("can invalidate ranges, leaving alone other elements") {
				expect(cache.get(5)) == 5
				expect(callsCount) == 1
				cache.invalidate(3..<5)
				expect(cache.get(5)) == 5
				expect(callsCount) == 1
				expect(cache.get(4)) == 4
				expect(callsCount) == 2
			}
		}
	}
}
