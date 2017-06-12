//: Playground - noun: a place where people can play

import RxSwift


enum E : String
{
	case Ciao
	case Come
	case Stai
}

let e=E.Ciao

print(e.rawValue)

protocol EmptyInitiable
{
	init()
}


protocol P1
{
	typealias T:EmptyInitiable
}

protocol P2
{
	typealias T:EmptyInitiable
}

class C<_T:EmptyInitiable>:P1
{
	typealias T=_T
	
}





	