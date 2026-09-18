import Base
import ./src/gauss.bend as Gauss

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

# Affine scales such as Celsius still construct temperature quantities.
law celsius_constructs_temperature:
  for displayed: F32
  Gauss.Quantity<Gauss.Dimension.temperature()>
