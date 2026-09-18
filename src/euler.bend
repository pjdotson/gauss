import Base

# Euler's quantities carry their physical dimension in the type. The dimension
# marker is erased, so a checked quantity is represented by one F32 at runtime.
type Scalar is Type:
  Scalar{}

type Length is Type:
  Length{}

type Time is Type:
  Time{}

type Mass is Type:
  Mass{}

type Speed is Type:
  Speed{}

type Acceleration is Type:
  Acceleration{}

type Force is Type:
  Force{}

type Energy is Type:
  Energy{}

type Quantity<-D: Type> is Data:
  Qty{value: F32}

# Quantities are stored in SI base units.
def scalar(value: F32) -> Quantity<Scalar>:
  Qty{value}

def meters(value: F32) -> Quantity<Length>:
  Qty{value}

def kilometers(value: F32) -> Quantity<Length>:
  Qty{(value * 1000.0 : F32)}

def feet(value: F32) -> Quantity<Length>:
  Qty{(value * 0.3048 : F32)}

def seconds(value: F32) -> Quantity<Time>:
  Qty{value}

def minutes(value: F32) -> Quantity<Time>:
  Qty{(value * 60.0 : F32)}

def kilograms(value: F32) -> Quantity<Mass>:
  Qty{value}

def pounds(value: F32) -> Quantity<Mass>:
  Qty{(value * 0.45359237 : F32)}

def value(-D: Type, quantity: Quantity<D>) -> F32:
  match quantity:
    case Qty{v}:
      v

def add(-D: Type, a: Quantity<D>, b: Quantity<D>) -> Quantity<D>:
  match a b:
    case Qty{a} Qty{b}:
      Qty{(a + b : F32)}

def scale(-D: Type, factor: F32, quantity: Quantity<D>) -> Quantity<D>:
  match quantity:
    case Qty{v}:
      Qty{(factor * v : F32)}

def speed(distance: Quantity<Length>, elapsed: Quantity<Time>) -> Quantity<Speed>:
  match distance elapsed:
    case Qty{distance} Qty{elapsed}:
      Qty{(distance / elapsed : F32)}

def acceleration(velocity: Quantity<Speed>, elapsed: Quantity<Time>) -> Quantity<Acceleration>:
  match velocity elapsed:
    case Qty{velocity} Qty{elapsed}:
      Qty{(velocity / elapsed : F32)}

def force(mass: Quantity<Mass>, acceleration: Quantity<Acceleration>) -> Quantity<Force>:
  match mass acceleration:
    case Qty{mass} Qty{acceleration}:
      Qty{(mass * acceleration : F32)}

def energy(force: Quantity<Force>, distance: Quantity<Length>) -> Quantity<Energy>:
  match force distance:
    case Qty{force} Qty{distance}:
      Qty{(force * distance : F32)}

def kinetic_energy(mass: Quantity<Mass>, velocity: Quantity<Speed>) -> Quantity<Energy>:
  match mass velocity:
    case Qty{mass} Qty{+velocity}:
      Qty{(0.5 * mass * velocity * velocity : F32)}

def show(-D: Type, unit: String, quantity: Quantity<D>) -> String:
  F32.show(value(D, quantity)) ++ " " ++ unit
