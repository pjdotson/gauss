import Base
import ./gauss.bend as Gauss
import ./runtime.bend as Runtime

# An arbitrary-precision rational backed by Bend's unbounded Nat. Arithmetic is
# exact; conversion to F32 is an explicit boundary operation.
type Rational is Data:
  Rational{negative: Bool, numerator: Nat, denominator: Nat}

def Rational.zero_sign(
  negative: Bool,
  numerator: Nat,
  denominator: Nat,
  zero: Bool
) -> Rational:
  match zero:
    case True{}:
      Rational{False{}, numerator, denominator}
    case False{}:
      Rational{negative, numerator, denominator}

def Rational.make(
  negative: Bool,
  +numerator: Nat,
  denominator: Nat
) -> Rational:
  Rational.zero_sign(negative, numerator, denominator, Nat.is_eq(numerator, 0n))

def Rational.integer(negative: Bool, value: Nat) -> Rational:
  Rational.make(negative, value, 1n)

def Rational.add.finish(
  left_negative: Bool,
  right_negative: Bool,
  left: Nat,
  right: Nat,
  denominator: Nat,
  order: Cmp
) -> Rational:
  match left_negative right_negative:
    case False{} False{}:
      Rational.make(False{}, Nat.add(left, right), denominator)
    case True{} True{}:
      Rational.make(True{}, Nat.add(left, right), denominator)
    case False{} True{}:
      match order:
        case LT{}:
          Rational.make(True{}, Nat.sub(right, left), denominator)
        case EQ{}:
          Rational.make(False{}, 0n, denominator)
        case GT{}:
          Rational.make(False{}, Nat.sub(left, right), denominator)
    case True{} False{}:
      match order:
        case LT{}:
          Rational.make(False{}, Nat.sub(right, left), denominator)
        case EQ{}:
          Rational.make(False{}, 0n, denominator)
        case GT{}:
          Rational.make(True{}, Nat.sub(left, right), denominator)

def Rational.add(left: Rational, right: Rational) -> Rational:
  match left right:
    case Rational{ln, +lv, +ld} Rational{rn, +rv, +rd}:
      +left_scaled = Nat.mul(lv, rd)
      +right_scaled = Nat.mul(rv, ld)
      Rational.add.finish(
        ln,
        rn,
        left_scaled,
        right_scaled,
        Nat.mul(ld, rd),
        Nat.cmp(left_scaled, right_scaled)
      )

def Rational.multiply(left: Rational, right: Rational) -> Rational:
  match left right:
    case Rational{ln, lv, ld} Rational{rn, rv, rd}:
      Rational.make(Bool.xor(ln, rn), Nat.mul(lv, rv), Nat.mul(ld, rd))

def Rational.divide.if(
  zero: Bool,
  left: Rational,
  right: Rational
) -> Result<&2, &2, Runtime.CalcError, Rational>:
  match zero:
    case True{}:
      Fail{Runtime.DivisionByZero{}}
    case False{}:
      match left right:
        case Rational{ln, lv, ld} Rational{rn, rv, rd}:
          Done{Rational.make(
            Bool.xor(ln, rn), Nat.mul(lv, rd), Nat.mul(ld, rv)
          )}

def Rational.divide(left: Rational, +right: Rational) ->
  Result<&2, &2, Runtime.CalcError, Rational>:
  match right:
    case Rational{negative, +numerator, denominator}:
      Rational.divide.if(
        Nat.is_eq(numerator, 0n),
        left,
        Rational{negative, numerator, denominator}
      )

def Rational.to_f32.signed(value: F32, negative: Bool) -> F32:
  match negative:
    case False{}:
      value
    case True{}:
      F32.neg(value)

def Rational.to_f32(value: Rational) -> F32:
  match value:
    case Rational{negative, numerator, denominator}:
      Rational.to_f32.signed(
        (F32.from_nat(numerator) / F32.from_nat(denominator) : F32),
        negative
      )

type ExactQuantity<-D: Gauss.Dimension> is Data:
  Exact{value: Rational}

def ExactQuantity.add(
  -D: Gauss.Dimension,
  left: ExactQuantity<D>,
  right: ExactQuantity<D>
) -> ExactQuantity<D>:
  match left right:
    case Exact{left} Exact{right}:
      Exact{Rational.add(left, right)}

def ExactQuantity.multiply(
  -A: Gauss.Dimension,
  -B: Gauss.Dimension,
  left: ExactQuantity<A>,
  right: ExactQuantity<B>
) -> ExactQuantity<Gauss.Dimension.multiply(A, B)>:
  match left right:
    case Exact{left} Exact{right}:
      Exact{Rational.multiply(left, right)}

def ExactQuantity.divide.result(
  -D: Gauss.Dimension,
  result: Result<&2, &2, Runtime.CalcError, Rational>
) -> Result<&2, &2, Runtime.CalcError, ExactQuantity<D>>:
  match result:
    case Fail{error}:
      Fail{error}
    case Done{value}:
      Done{Exact{value}}

def ExactQuantity.divide(
  -A: Gauss.Dimension,
  -B: Gauss.Dimension,
  left: ExactQuantity<A>,
  right: ExactQuantity<B>
) -> Result<&2, &2, Runtime.CalcError, ExactQuantity<Gauss.Dimension.divide(A, B)>>:
  match left right:
    case Exact{left} Exact{right}:
      ExactQuantity.divide.result(
        Gauss.Dimension.divide(A, B), Rational.divide(left, right)
      )
