import Base
import ./src/euler.bend as Euler

# A tiny engineering worksheet: estimate the kinetic energy of a 1,500 kg car
# traveling 100 km in one hour. All intermediate values are SI quantities.
def main() -> IO(Unit):
  do IO<Unit>:
    distance : Euler.Quantity<Euler.Length> = Euler.kilometers(100.0)
    elapsed : Euler.Quantity<Euler.Time> = Euler.minutes(60.0)
    +velocity : Euler.Quantity<Euler.Speed> = Euler.speed(distance, elapsed)
    mass : Euler.Quantity<Euler.Mass> = Euler.kilograms(1500.0)
    energy : Euler.Quantity<Euler.Energy> = Euler.kinetic_energy(mass, velocity)
    IO.print("Euler engineering worksheet")
    IO.print("speed  = " ++ Euler.show(Euler.Speed, "m/s", velocity))
    IO.print("energy = " ++ Euler.show(Euler.Energy, "J", energy))
