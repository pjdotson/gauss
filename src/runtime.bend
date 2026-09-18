import Base
import ./gauss.bend as Gauss

type CalcError is Data:
  DivisionByZero{}
  NegativeSquareRoot{value: F32}
  InvalidRoot{input: Gauss.Dimension, requested: Gauss.Dimension}
  DimensionMismatch{left: Gauss.Dimension, right: Gauss.Dimension}
  UnknownUnit{name: String}
  InvalidNumber{text: String}
  InvalidFormula{message: String}
  UnknownCell{name: String}
  CycleDetected{name: String}

type DynamicQuantity is Data:
  Dynamic{dimension: Gauss.Dimension, value: F32}

def Quantity.divide.if(
  -D: Gauss.Dimension,
  zero: Bool,
  left: F32,
  right: F32
) -> Result<&2, &2, CalcError, Gauss.Quantity<D>>:
  match zero:
    case True{}:
      Fail{DivisionByZero{}}
    case False{}:
      Done{Gauss.Qty{(left / right : F32)}}

def Quantity.divide(
  -A: Gauss.Dimension,
  -B: Gauss.Dimension,
  left: Gauss.Quantity<A>,
  right: Gauss.Quantity<B>
) -> Result<&2, &2, CalcError, Gauss.Quantity<Gauss.Dimension.divide(A, B)>>:
  match left right:
    case Gauss.Qty{left} Gauss.Qty{+right}:
      Quantity.divide.if(
        Gauss.Dimension.divide(A, B),
        F32.is_eq(right, 0.0),
        left,
        right
      )

def Quantity.sqrt.if(
  -D: Gauss.Dimension,
  negative: Bool,
  value: F32
) -> Result<&2, &2, CalcError, Gauss.Quantity<D>>:
  match negative:
    case True{}:
      Fail{NegativeSquareRoot{value}}
    case False{}:
      Done{Gauss.Qty{F32.sqrt(value)}}

def Quantity.sqrt(
  -D: Gauss.Dimension,
  quantity: Gauss.Quantity<Gauss.Dimension.pow(D, 2n)>
) -> Result<&2, &2, CalcError, Gauss.Quantity<D>>:
  match quantity:
    case Gauss.Qty{+value}:
      Quantity.sqrt.if(D, F32.is_lt(value, 0.0), value)

def Dynamic.from_typed(+D: Gauss.Dimension, quantity: Gauss.Quantity<D>) -> DynamicQuantity:
  match quantity:
    case Gauss.Qty{value}:
      Dynamic{D, value}

def Dynamic.add.if(
  left_dimension: Gauss.Dimension,
  right_dimension: Gauss.Dimension,
  left: F32,
  right: F32,
  same: Bool
) -> Result<&2, &2, CalcError, DynamicQuantity>:
  match same:
    case True{}:
      Done{Dynamic{left_dimension, (left + right : F32)}}
    case False{}:
      Fail{DimensionMismatch{left_dimension, right_dimension}}

def Dynamic.add(left: DynamicQuantity, right: DynamicQuantity) ->
  Result<&2, &2, CalcError, DynamicQuantity>:
  match left right:
    case Dynamic{+ld, lv} Dynamic{+rd, rv}:
      Dynamic.add.if(ld, rd, lv, rv, Gauss.Dimension.is_equal(ld, rd))

def Dynamic.subtract.if(
  left_dimension: Gauss.Dimension,
  right_dimension: Gauss.Dimension,
  left: F32,
  right: F32,
  same: Bool
) -> Result<&2, &2, CalcError, DynamicQuantity>:
  match same:
    case True{}:
      Done{Dynamic{left_dimension, (left - right : F32)}}
    case False{}:
      Fail{DimensionMismatch{left_dimension, right_dimension}}

def Dynamic.subtract(left: DynamicQuantity, right: DynamicQuantity) ->
  Result<&2, &2, CalcError, DynamicQuantity>:
  match left right:
    case Dynamic{+ld, lv} Dynamic{+rd, rv}:
      Dynamic.subtract.if(ld, rd, lv, rv, Gauss.Dimension.is_equal(ld, rd))

def Dynamic.multiply(left: DynamicQuantity, right: DynamicQuantity) -> DynamicQuantity:
  match left right:
    case Dynamic{ld, lv} Dynamic{rd, rv}:
      Dynamic{Gauss.Dimension.multiply(ld, rd), (lv * rv : F32)}

def Dynamic.divide.if(
  left_dimension: Gauss.Dimension,
  right_dimension: Gauss.Dimension,
  left: F32,
  right: F32,
  zero: Bool
) -> Result<&2, &2, CalcError, DynamicQuantity>:
  match zero:
    case True{}:
      Fail{DivisionByZero{}}
    case False{}:
      Done{Dynamic{
        Gauss.Dimension.divide(left_dimension, right_dimension),
        (left / right : F32)
      }}

def Dynamic.divide(left: DynamicQuantity, right: DynamicQuantity) ->
  Result<&2, &2, CalcError, DynamicQuantity>:
  match left right:
    case Dynamic{ld, lv} Dynamic{rd, +rv}:
      Dynamic.divide.if(ld, rd, lv, rv, F32.is_eq(rv, 0.0))

def Dynamic.power(quantity: DynamicQuantity, +exponent: Nat) -> DynamicQuantity:
  match quantity:
    case Dynamic{dimension, value}:
      Dynamic{
        Gauss.Dimension.pow(dimension, exponent),
        F32.pow(value, F32.from_nat(exponent))
      }

def Dynamic.sqrt.value(
  root: Gauss.Dimension,
  +value: F32,
  negative: Bool
) -> Result<&2, &2, CalcError, DynamicQuantity>:
  match negative:
    case True{}:
      Fail{NegativeSquareRoot{value}}
    case False{}:
      Done{Dynamic{root, F32.sqrt(value)}}

def Dynamic.sqrt.dimension(
  input: Gauss.Dimension,
  +root: Gauss.Dimension,
  +value: F32,
  valid: Bool
) -> Result<&2, &2, CalcError, DynamicQuantity>:
  match valid:
    case True{}:
      Dynamic.sqrt.value(root, value, F32.is_lt(value, 0.0))
    case False{}:
      Fail{InvalidRoot{input, root}}

# The requested root is explicit so Bend can check that root^2 matches the
# runtime input dimension before evaluating the numeric square root.
def Dynamic.sqrt(+root: Gauss.Dimension, quantity: DynamicQuantity) ->
  Result<&2, &2, CalcError, DynamicQuantity>:
  match quantity:
    case Dynamic{+input, value}:
      Dynamic.sqrt.dimension(
        input,
        root,
        value,
        Gauss.Dimension.is_equal(input, Gauss.Dimension.pow(root, 2n))
      )

type RuntimeUnit is Data:
  RuntimeUnit{
    dimension: Gauss.Dimension,
    scale: F32,
    offset: F32,
    symbol: String
  }

def UnitRegistry.map() -> Map<&2, RuntimeUnit>:
  map = Map.new(&2, RuntimeUnit)
  map = Map.set(&2, RuntimeUnit, map, "1", RuntimeUnit{Gauss.Dimension.scalar(), 1.0, 0.0, ""})
  map = Map.set(&2, RuntimeUnit, map, "m", RuntimeUnit{Gauss.Dimension.length(), 1.0, 0.0, "m"})
  map = Map.set(&2, RuntimeUnit, map, "km", RuntimeUnit{Gauss.Dimension.length(), 1000.0, 0.0, "km"})
  map = Map.set(&2, RuntimeUnit, map, "ft", RuntimeUnit{Gauss.Dimension.length(), 0.3048, 0.0, "ft"})
  map = Map.set(&2, RuntimeUnit, map, "in", RuntimeUnit{Gauss.Dimension.length(), 0.0254, 0.0, "in"})
  map = Map.set(&2, RuntimeUnit, map, "s", RuntimeUnit{Gauss.Dimension.time(), 1.0, 0.0, "s"})
  map = Map.set(&2, RuntimeUnit, map, "min", RuntimeUnit{Gauss.Dimension.time(), 60.0, 0.0, "min"})
  map = Map.set(&2, RuntimeUnit, map, "h", RuntimeUnit{Gauss.Dimension.time(), 3600.0, 0.0, "h"})
  map = Map.set(&2, RuntimeUnit, map, "kg", RuntimeUnit{Gauss.Dimension.mass(), 1.0, 0.0, "kg"})
  map = Map.set(&2, RuntimeUnit, map, "lb", RuntimeUnit{Gauss.Dimension.mass(), 0.45359237, 0.0, "lb"})
  map = Map.set(&2, RuntimeUnit, map, "g", RuntimeUnit{Gauss.Dimension.mass(), 0.001, 0.0, "g"})
  map = Map.set(&2, RuntimeUnit, map, "t", RuntimeUnit{Gauss.Dimension.mass(), 1000.0, 0.0, "t"})
  map = Map.set(&2, RuntimeUnit, map, "A", RuntimeUnit{Gauss.Dimension.current(), 1.0, 0.0, "A"})
  map = Map.set(&2, RuntimeUnit, map, "deltaK", RuntimeUnit{Gauss.Dimension.temperature(), 1.0, 0.0, "deltaK"})
  map = Map.set(&2, RuntimeUnit, map, "deltaC", RuntimeUnit{Gauss.Dimension.temperature(), 1.0, 0.0, "deltaC"})
  map = Map.set(&2, RuntimeUnit, map, "mol", RuntimeUnit{Gauss.Dimension.amount(), 1.0, 0.0, "mol"})
  map = Map.set(&2, RuntimeUnit, map, "cd", RuntimeUnit{Gauss.Dimension.luminosity(), 1.0, 0.0, "cd"})
  map = Map.set(&2, RuntimeUnit, map, "m/s", RuntimeUnit{Gauss.Dimension.speed(), 1.0, 0.0, "m/s"})
  map = Map.set(&2, RuntimeUnit, map, "km/h", RuntimeUnit{Gauss.Dimension.speed(), (1000.0 / 3600.0 : F32), 0.0, "km/h"})
  map = Map.set(&2, RuntimeUnit, map, "Hz", RuntimeUnit{Gauss.Dimension.frequency(), 1.0, 0.0, "Hz"})
  map = Map.set(&2, RuntimeUnit, map, "N", RuntimeUnit{Gauss.Dimension.force(), 1.0, 0.0, "N"})
  map = Map.set(&2, RuntimeUnit, map, "kN", RuntimeUnit{Gauss.Dimension.force(), 1000.0, 0.0, "kN"})
  map = Map.set(&2, RuntimeUnit, map, "lbf", RuntimeUnit{Gauss.Dimension.force(), 4.4482216, 0.0, "lbf"})
  map = Map.set(&2, RuntimeUnit, map, "J", RuntimeUnit{Gauss.Dimension.energy(), 1.0, 0.0, "J"})
  map = Map.set(&2, RuntimeUnit, map, "kJ", RuntimeUnit{Gauss.Dimension.energy(), 1000.0, 0.0, "kJ"})
  map = Map.set(&2, RuntimeUnit, map, "Wh", RuntimeUnit{Gauss.Dimension.energy(), 3600.0, 0.0, "Wh"})
  map = Map.set(&2, RuntimeUnit, map, "kWh", RuntimeUnit{Gauss.Dimension.energy(), 3600000.0, 0.0, "kWh"})
  map = Map.set(&2, RuntimeUnit, map, "Pa", RuntimeUnit{Gauss.Dimension.pressure(), 1.0, 0.0, "Pa"})
  map = Map.set(&2, RuntimeUnit, map, "kPa", RuntimeUnit{Gauss.Dimension.pressure(), 1000.0, 0.0, "kPa"})
  map = Map.set(&2, RuntimeUnit, map, "MPa", RuntimeUnit{Gauss.Dimension.pressure(), 1000000.0, 0.0, "MPa"})
  map = Map.set(&2, RuntimeUnit, map, "psi", RuntimeUnit{Gauss.Dimension.pressure(), 6894.757, 0.0, "psi"})
  map = Map.set(&2, RuntimeUnit, map, "W", RuntimeUnit{Gauss.Dimension.power(), 1.0, 0.0, "W"})
  map = Map.set(&2, RuntimeUnit, map, "kW", RuntimeUnit{Gauss.Dimension.power(), 1000.0, 0.0, "kW"})
  map = Map.set(&2, RuntimeUnit, map, "C", RuntimeUnit{Gauss.Dimension.charge(), 1.0, 0.0, "C"})
  map = Map.set(&2, RuntimeUnit, map, "V", RuntimeUnit{Gauss.Dimension.voltage(), 1.0, 0.0, "V"})
  Map.set(&2, RuntimeUnit, map, "ohm", RuntimeUnit{Gauss.Dimension.resistance(), 1.0, 0.0, "ohm"})

def UnitRegistry.get.value(pair: Map<&2, RuntimeUnit> & RuntimeUnit) ->
  Result<&2, &2, CalcError, RuntimeUnit>:
  (map, unit) = pair
  Done{unit}

def UnitRegistry.get.if(
  name: String,
  pair: Map<&2, RuntimeUnit> & Bool
) -> Result<&2, &2, CalcError, RuntimeUnit>:
  (map, found) = pair
  match found:
    case True{}:
      default = {RuntimeUnit{Gauss.Dimension.scalar(), 1.0, 0.0, ""} : RuntimeUnit}
      UnitRegistry.get.value(Map.get(RuntimeUnit, default, map, name))
    case False{}:
      Fail{UnknownUnit{name}}

def UnitRegistry.get(+name: String) -> Result<&2, &2, CalcError, RuntimeUnit>:
  UnitRegistry.get.if(name, Map.has(&2, RuntimeUnit, UnitRegistry.map(), name))

def RuntimeUnit.quantity(unit: RuntimeUnit, displayed: F32) -> DynamicQuantity:
  match unit:
    case RuntimeUnit{dimension, scale, offset, symbol}:
      Dynamic{dimension, (displayed * scale + offset : F32)}

def RuntimeUnit.format.if(
  unit_dimension: Gauss.Dimension,
  quantity_dimension: Gauss.Dimension,
  scale: F32,
  offset: F32,
  symbol: String,
  value: F32,
  same: Bool
) -> Result<&2, &2, CalcError, String>:
  match same:
    case True{}:
      Done{F32.show(((value - offset : F32) / scale : F32)) ++ " " ++ symbol}
    case False{}:
      Fail{DimensionMismatch{quantity_dimension, unit_dimension}}

def RuntimeUnit.format(unit: RuntimeUnit, quantity: DynamicQuantity) ->
  Result<&2, &2, CalcError, String>:
  match unit quantity:
    case RuntimeUnit{+ud, scale, offset, symbol} Dynamic{+qd, value}:
      RuntimeUnit.format.if(
        ud, qd, scale, offset, symbol, value,
        Gauss.Dimension.is_equal(ud, qd)
      )

# Absolute temperature and temperature intervals are distinct values. This
# prevents accidentally adding two absolute temperatures.
type AbsoluteTemperature is Data:
  AbsoluteTemperature{kelvin: F32}

type TemperatureDelta is Data:
  TemperatureDelta{kelvin: F32}

def Temperature.kelvin(value: F32) -> AbsoluteTemperature:
  AbsoluteTemperature{value}

def Temperature.celsius(value: F32) -> AbsoluteTemperature:
  AbsoluteTemperature{(value + 273.15 : F32)}

def Temperature.delta_kelvin(value: F32) -> TemperatureDelta:
  TemperatureDelta{value}

def Temperature.delta_celsius(value: F32) -> TemperatureDelta:
  TemperatureDelta{value}

def Temperature.add_delta(
  absolute: AbsoluteTemperature,
  delta: TemperatureDelta
) -> AbsoluteTemperature:
  match absolute delta:
    case AbsoluteTemperature{absolute} TemperatureDelta{delta}:
      AbsoluteTemperature{(absolute + delta : F32)}

def Temperature.difference(
  high: AbsoluteTemperature,
  low: AbsoluteTemperature
) -> TemperatureDelta:
  match high low:
    case AbsoluteTemperature{high} AbsoluteTemperature{low}:
      TemperatureDelta{(high - low : F32)}

def Temperature.format_kelvin(temperature: AbsoluteTemperature) -> String:
  match temperature:
    case AbsoluteTemperature{value}:
      F32.show(value) ++ " K"

def Temperature.format_celsius(temperature: AbsoluteTemperature) -> String:
  match temperature:
    case AbsoluteTemperature{value}:
      F32.show((value - 273.15 : F32)) ++ " degC"
