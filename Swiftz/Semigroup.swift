//
//  Semigroup.swift
//  swiftz
//
//  Created by Maxwell Swadling on 3/06/2014.
//  Copyright (c) 2014 Maxwell Swadling. All rights reserved.
//

/// A Semigroup is a type with a closed, associative, binary operator.
public protocol Semigroup {

	/// An associative binary operator.
	func op(other : Self) -> Self
}

public func <> <A : Semigroup>(lhs : A, rhs : A) -> A {
	return lhs.op(rhs)
}

public func sconcat<S: Semigroup>(h : S, t : [S]) -> S {
	return t.reduce(h) { $0.op($1) }
}

/// The Semigroup of comparable values under MIN().
public struct Min<A: Comparable>: Semigroup {
	public let value : () -> A

	public init(@autoclosure(escaping) _ x : () -> A) {
		value = x
	}

	public func op(other : Min<A>) -> Min<A> {
		if self.value() < other.value() {
			return self
		} else {
			return other
		}
	}
}

/// The Semigroup of comparable values under MAX().
public struct Max<A: Comparable> : Semigroup {
	public let value : () -> A

	public init(@autoclosure(escaping) _ x : () -> A) {
		value = x
	}

	public func op(other : Max<A>) -> Max<A> {
		if other.value() < self.value() {
			return self
		} else {
			return other
		}
	}
}

/// The coproduct of `Semigroup`s
public struct Vacillate<A : Semigroup, B : Semigroup> : Semigroup {
	public let values : [Either<A, B>] // this array will never be empty

	public init(_ vs : [Either<A, B>]) {
//		if vs.isEmpty { 
//			error("Cannot construct a \(Vacillate<A, B>.self) with no elements.") 
//		}
		var vals = [Either<A, B>]()
		for v in vs {
			if let z = vals.last {
				switch (z, v) {
				case let (.Left(x), .Left(y)): vals[vals.endIndex - 1] = Either.left(x.value.op(y.value))
				case let (.Right(x), .Right(y)): vals[vals.endIndex - 1] = Either.right(x.value.op(y.value))
				default: vals.append(v)
				}
			} else {
				vals = [v]
			}
		}
		self.values = vals
	}

	public static func left(x: A) -> Vacillate<A, B> {
		return Vacillate([Either.left(x)])
	}

	public static func right(y: B) -> Vacillate<A, B> {
		return Vacillate([Either.right(y)])
	}

	public func fold<C : Monoid>(onLeft f : A -> C, onRight g : B -> C) -> C {
		return foldRight(values)(z: C.mzero) { v, acc in v.either(f, g).op(acc) }
	}

	public func op(other : Vacillate<A, B>) -> Vacillate<A, B> {
		return Vacillate(values + other.values)
	}
}
