import Base
import ./src/gauss.bend as Gauss
import ./src/runtime.bend as Runtime
import ./src/exact.bend as Exact

# Dividing length by time produces the canonical speed dimension L T^-1.
law speed_dimension_is_canonical:
  {Gauss.Dimension.speed() == Gauss.Dim{
    Gauss.EPos{0n}, Gauss.EZero{}, Gauss.ENeg{0n}, Gauss.EZero{},
    Gauss.EZero{}, Gauss.EZero{}, Gauss.EZero{}
  } : Gauss.Dimension}

# Multiplying speed by time cancels the time exponent and recovers length.
law speed_times_time_is_length:
  {Gauss.Dimension.multiply(
    Gauss.Dimension.speed(),
    Gauss.Dimension.time()
  ) == Gauss.Dimension.length() : Gauss.Dimension}

# Force reduces to M L T^-2.
law force_dimension_is_canonical:
  {Gauss.Dimension.force() == Gauss.Dim{
    Gauss.EPos{0n}, Gauss.EPos{0n}, Gauss.ENeg{1n}, Gauss.EZero{},
    Gauss.EZero{}, Gauss.EZero{}, Gauss.EZero{}
  } : Gauss.Dimension}

# Energy reduces to M L^2 T^-2.
law energy_dimension_is_canonical:
  {Gauss.Dimension.energy() == Gauss.Dim{
    Gauss.EPos{1n}, Gauss.EPos{0n}, Gauss.ENeg{1n}, Gauss.EZero{},
    Gauss.EZero{}, Gauss.EZero{}, Gauss.EZero{}
  } : Gauss.Dimension}

# Pressure reduces to M L^-1 T^-2, exercising unequal exponent cancellation.
law pressure_dimension_is_canonical:
  {Gauss.Dimension.pressure() == Gauss.Dim{
    Gauss.ENeg{0n}, Gauss.EPos{0n}, Gauss.ENeg{1n}, Gauss.EZero{},
    Gauss.EZero{}, Gauss.EZero{}, Gauss.EZero{}
  } : Gauss.Dimension}

# Electrical resistance reduces to M L^2 T^-3 I^-2.
law resistance_dimension_is_canonical:
  {Gauss.Dimension.resistance() == Gauss.Dim{
    Gauss.EPos{1n}, Gauss.EPos{0n}, Gauss.ENeg{2n}, Gauss.ENeg{1n},
    Gauss.EZero{}, Gauss.EZero{}, Gauss.EZero{}
  } : Gauss.Dimension}

# Unit specifications can format only quantities with the same dimension.
law speed_format_is_dimension_safe:
  for velocity: Gauss.Quantity<Gauss.Dimension.speed()>
  String

# Affine scales such as Celsius construct absolute temperatures, not quantities
# that can be freely added or multiplied.
law celsius_constructs_absolute_temperature:
  for displayed: F32
  Runtime.AbsoluteTemperature

# Integer powers compose dimensions canonically.
law length_cubed_is_volume:
  {Gauss.Dimension.pow(
    Gauss.Dimension.length(), 3n
  ) == Gauss.Dimension.volume() : Gauss.Dimension}

# A square root can only request the dimension whose square matches the input.
law area_square_root_is_length:
  for area: Gauss.Quantity<Gauss.Dimension.area()>
  Result<&2, &2, Runtime.CalcError, Gauss.Quantity<Gauss.Dimension.length()>>

# Absolute temperatures and differences remain distinct at the type level.
law temperature_plus_delta_is_absolute:
  for absolute: Runtime.AbsoluteTemperature
  for delta: Runtime.TemperatureDelta
  Runtime.AbsoluteTemperature

# Exact quantities retain the same dimension algebra as F32 quantities.
law exact_length_times_length_is_area:
  for left: Exact.ExactQuantity<Gauss.Dimension.length()>
  for right: Exact.ExactQuantity<Gauss.Dimension.length()>
  Exact.ExactQuantity<Gauss.Dimension.area()>
