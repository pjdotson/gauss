import Base
import ./src/gauss.bend as Gauss

# A tiny engineering worksheet: estimate the kinetic energy of a 1,500 kg car
# traveling 100 km in one hour. All intermediate values are SI quantities.
def main() -> IO(Unit):
  do IO<Unit>:
    distance : Gauss.Quantity<Gauss.Length> = Gauss.kilometers(100.0)
    elapsed : Gauss.Quantity<Gauss.Time> = Gauss.minutes(60.0)
    +velocity : Gauss.Quantity<Gauss.Speed> = Gauss.speed(distance, elapsed)
    mass : Gauss.Quantity<Gauss.Mass> = Gauss.kilograms(1500.0)
    energy : Gauss.Quantity<Gauss.Energy> = Gauss.kinetic_energy(mass, velocity)
    IO.print("Gauss engineering worksheet")
    IO.print("speed  = " ++ Gauss.show(Gauss.Speed, "m/s", velocity))
    IO.print("energy = " ++ Gauss.show(Gauss.Energy, "J", energy))
