import Base
import ./LAWS.bend as Laws
import ./src/gauss.bend as Gauss

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

def Laws.celsius_constructs_temperature(displayed):
  Gauss.from_unit(
    Gauss.Dimension.temperature(),
    Gauss.Units.celsius(),
    displayed
  )
