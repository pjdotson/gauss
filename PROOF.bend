import Base
import ./LAWS.bend as Laws
import ./src/gauss.bend as Gauss
import ./src/runtime.bend as Runtime
import ./src/exact.bend as Exact

def Laws.speed_dimension_is_canonical():
  {==}

def Laws.speed_times_time_is_length():
  {==}

def Laws.force_dimension_is_canonical():
  {==}

def Laws.energy_dimension_is_canonical():
  {==}

def Laws.pressure_dimension_is_canonical():
  {==}

def Laws.resistance_dimension_is_canonical():
  {==}

def Laws.speed_format_is_dimension_safe(velocity):
  Gauss.format(
    Gauss.Dimension.speed(),
    Gauss.Units.kilometer_per_hour(),
    velocity
  )

def Laws.celsius_constructs_absolute_temperature(displayed):
  Runtime.Temperature.celsius(displayed)

def Laws.length_cubed_is_volume():
  {==}

def Laws.area_square_root_is_length(area):
  Runtime.Quantity.sqrt(Gauss.Dimension.length(), area)

def Laws.temperature_plus_delta_is_absolute(absolute, delta):
  Runtime.Temperature.add_delta(absolute, delta)

def Laws.exact_length_times_length_is_area(left, right):
  Exact.ExactQuantity.multiply(
    Gauss.Dimension.length(), Gauss.Dimension.length(), left, right
  )
