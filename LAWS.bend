import Base
import ./src/euler.bend as Euler

# A length divided by a time produces a speed.
law speed_has_correct_dimension:
  for distance: Euler.Quantity<Euler.Length>
  for elapsed: Euler.Quantity<Euler.Time>
  Euler.Quantity<Euler.Speed>

# Mass times acceleration produces force.
law force_has_correct_dimension:
  for mass: Euler.Quantity<Euler.Mass>
  for acceleration: Euler.Quantity<Euler.Acceleration>
  Euler.Quantity<Euler.Force>

# Mass and speed produce kinetic energy, never an unlabelled scalar.
law kinetic_energy_has_correct_dimension:
  for mass: Euler.Quantity<Euler.Mass>
  for velocity: Euler.Quantity<Euler.Speed>
  Euler.Quantity<Euler.Energy>
