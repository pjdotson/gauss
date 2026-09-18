import Base
import ./LAWS.bend as Laws
import ./src/euler.bend as Euler

def Laws.speed_has_correct_dimension(distance, elapsed):
  Euler.speed(distance, elapsed)

def Laws.force_has_correct_dimension(mass, acceleration):
  Euler.force(mass, acceleration)

def Laws.kinetic_energy_has_correct_dimension(mass, velocity):
  Euler.kinetic_energy(mass, velocity)
