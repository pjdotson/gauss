import Base
import ./src/gauss.bend as Gauss

# A length divided by a time produces a speed.
law speed_has_correct_dimension:
  for distance: Gauss.Quantity<Gauss.Length>
  for elapsed: Gauss.Quantity<Gauss.Time>
  Gauss.Quantity<Gauss.Speed>

# Mass times acceleration produces force.
law force_has_correct_dimension:
  for mass: Gauss.Quantity<Gauss.Mass>
  for acceleration: Gauss.Quantity<Gauss.Acceleration>
  Gauss.Quantity<Gauss.Force>

# Mass and speed produce kinetic energy, never an unlabelled scalar.
law kinetic_energy_has_correct_dimension:
  for mass: Gauss.Quantity<Gauss.Mass>
  for velocity: Gauss.Quantity<Gauss.Speed>
  Gauss.Quantity<Gauss.Energy>
