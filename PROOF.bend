import Base
import ./LAWS.bend as Laws
import ./src/gauss.bend as Gauss

def Laws.speed_has_correct_dimension(distance, elapsed):
  Gauss.speed(distance, elapsed)

def Laws.force_has_correct_dimension(mass, acceleration):
  Gauss.force(mass, acceleration)

def Laws.kinetic_energy_has_correct_dimension(mass, velocity):
  Gauss.kinetic_energy(mass, velocity)
