import Base
import ./src/gauss.bend as Gauss

# A tiny engineering worksheet: estimate the kinetic energy of a 1,500 kg car
# traveling 100 km in one hour. All intermediate values are SI quantities.
def main() -> IO(Unit):
  do IO<Unit>:
    distance : Gauss.Quantity<Gauss.Dimension.length()> = Gauss.kilometers(100.0)
    elapsed : Gauss.Quantity<Gauss.Dimension.time()> = Gauss.minutes(60.0)
    +velocity : Gauss.Quantity<Gauss.Dimension.speed()> = Gauss.speed(distance, elapsed)
    mass : Gauss.Quantity<Gauss.Dimension.mass()> = Gauss.kilograms(1500.0)
    energy : Gauss.Quantity<Gauss.Dimension.energy()> = Gauss.kinetic_energy(mass, velocity)
    ambient : Gauss.Quantity<Gauss.Dimension.temperature()> = Gauss.celsius(20.0)
    IO.print("Gauss engineering worksheet")
    IO.print("speed  = " ++ Gauss.format(
      Gauss.Dimension.speed(), Gauss.Units.kilometer_per_hour(), velocity
    ))
    IO.print("energy = " ++ Gauss.format(
      Gauss.Dimension.energy(), Gauss.Units.kilojoule(), energy
    ))
    IO.print("ambient SI = " ++ Gauss.format(
      Gauss.Dimension.temperature(), Gauss.Units.kelvin(), ambient
    ))
