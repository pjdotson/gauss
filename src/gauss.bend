import Base

# Signed, canonical SI exponents. EPos{n} means +(n + 1), while ENeg{n}
# means -(n + 1). The representation has exactly one zero value, which makes
# structurally equal dimensions reduce to the same term in the type checker.
type Exponent is Data:
  EZero{}
  EPos{pred: Nat}
  ENeg{pred: Nat}

def Exponent.negate(exponent: Exponent) -> Exponent:
  match exponent:
    case EZero{}:
      EZero{}
    case EPos{pred}:
      ENeg{pred}
    case ENeg{pred}:
      EPos{pred}

def Exponent.add_opposite(positive: Nat, negative: Nat, order: Cmp) -> Exponent:
  match order:
    case LT{}:
      ENeg{Nat.sub(negative, 1n+positive)}
    case EQ{}:
      EZero{}
    case GT{}:
      EPos{Nat.sub(positive, 1n+negative)}

def Exponent.add(left: Exponent, right: Exponent) -> Exponent:
  match left right:
    case EZero{} exponent:
      exponent
    case EPos{pred} EZero{}:
      EPos{pred}
    case ENeg{pred} EZero{}:
      ENeg{pred}
    case EPos{left} EPos{right}:
      EPos{1n+Nat.add(left, right)}
    case ENeg{left} ENeg{right}:
      ENeg{1n+Nat.add(left, right)}
    case EPos{+positive} ENeg{+negative}:
      Exponent.add_opposite(positive, negative, Nat.cmp(positive, negative))
    case ENeg{+negative} EPos{+positive}:
      Exponent.add_opposite(positive, negative, Nat.cmp(positive, negative))

# The seven axes are length, mass, time, electric current, temperature,
# amount of substance, and luminous intensity, in SI order.
type Dimension is Data:
  Dim{
    length: Exponent,
    mass: Exponent,
    time: Exponent,
    current: Exponent,
    temperature: Exponent,
    amount: Exponent,
    luminosity: Exponent
  }

def Dimension.scalar() -> Dimension:
  Dim{EZero{}, EZero{}, EZero{}, EZero{}, EZero{}, EZero{}, EZero{}}

def Dimension.length() -> Dimension:
  Dim{EPos{0n}, EZero{}, EZero{}, EZero{}, EZero{}, EZero{}, EZero{}}

def Dimension.mass() -> Dimension:
  Dim{EZero{}, EPos{0n}, EZero{}, EZero{}, EZero{}, EZero{}, EZero{}}

def Dimension.time() -> Dimension:
  Dim{EZero{}, EZero{}, EPos{0n}, EZero{}, EZero{}, EZero{}, EZero{}}

def Dimension.current() -> Dimension:
  Dim{EZero{}, EZero{}, EZero{}, EPos{0n}, EZero{}, EZero{}, EZero{}}

def Dimension.temperature() -> Dimension:
  Dim{EZero{}, EZero{}, EZero{}, EZero{}, EPos{0n}, EZero{}, EZero{}}

def Dimension.amount() -> Dimension:
  Dim{EZero{}, EZero{}, EZero{}, EZero{}, EZero{}, EPos{0n}, EZero{}}

def Dimension.luminosity() -> Dimension:
  Dim{EZero{}, EZero{}, EZero{}, EZero{}, EZero{}, EZero{}, EPos{0n}}

def Dimension.inverse(dimension: Dimension) -> Dimension:
  match dimension:
    case Dim{length, mass, time, current, temperature, amount, luminosity}:
      Dim{
        Exponent.negate(length),
        Exponent.negate(mass),
        Exponent.negate(time),
        Exponent.negate(current),
        Exponent.negate(temperature),
        Exponent.negate(amount),
        Exponent.negate(luminosity)
      }

def Dimension.multiply(left: Dimension, right: Dimension) -> Dimension:
  match left right:
    case Dim{ll, lm, lt, li, lk, ln, lj} Dim{rl, rm, rt, ri, rk, rn, rj}:
      Dim{
        Exponent.add(ll, rl),
        Exponent.add(lm, rm),
        Exponent.add(lt, rt),
        Exponent.add(li, ri),
        Exponent.add(lk, rk),
        Exponent.add(ln, rn),
        Exponent.add(lj, rj)
      }

def Dimension.divide(left: Dimension, right: Dimension) -> Dimension:
  Dimension.multiply(left, Dimension.inverse(right))

def Dimension.speed() -> Dimension:
  Dimension.divide(Dimension.length(), Dimension.time())

def Dimension.acceleration() -> Dimension:
  Dimension.divide(Dimension.speed(), Dimension.time())

def Dimension.force() -> Dimension:
  Dimension.multiply(Dimension.mass(), Dimension.acceleration())

def Dimension.energy() -> Dimension:
  Dimension.multiply(Dimension.force(), Dimension.length())

def Dimension.area() -> Dimension:
  Dimension.multiply(Dimension.length(), Dimension.length())

def Dimension.volume() -> Dimension:
  Dimension.multiply(Dimension.area(), Dimension.length())

def Dimension.frequency() -> Dimension:
  Dimension.divide(Dimension.scalar(), Dimension.time())

def Dimension.pressure() -> Dimension:
  Dimension.divide(Dimension.force(), Dimension.area())

def Dimension.power() -> Dimension:
  Dimension.divide(Dimension.energy(), Dimension.time())

def Dimension.charge() -> Dimension:
  Dimension.multiply(Dimension.current(), Dimension.time())

def Dimension.voltage() -> Dimension:
  Dimension.divide(Dimension.power(), Dimension.current())

def Dimension.resistance() -> Dimension:
  Dimension.divide(Dimension.voltage(), Dimension.current())

# The dimension parameter is erased, so every checked quantity is represented
# by exactly one F32 at runtime.
type Quantity<-D: Dimension> is Data:
  Qty{value: F32}

def scalar(value: F32) -> Quantity<Dimension.scalar()>:
  Qty{value}

def meters(value: F32) -> Quantity<Dimension.length()>:
  Qty{value}

def kilometers(value: F32) -> Quantity<Dimension.length()>:
  Qty{(value * 1000.0 : F32)}

def feet(value: F32) -> Quantity<Dimension.length()>:
  Qty{(value * 0.3048 : F32)}

def seconds(value: F32) -> Quantity<Dimension.time()>:
  Qty{value}

def minutes(value: F32) -> Quantity<Dimension.time()>:
  Qty{(value * 60.0 : F32)}

def kilograms(value: F32) -> Quantity<Dimension.mass()>:
  Qty{value}

def pounds(value: F32) -> Quantity<Dimension.mass()>:
  Qty{(value * 0.45359237 : F32)}

def amperes(value: F32) -> Quantity<Dimension.current()>:
  Qty{value}

def kelvin(value: F32) -> Quantity<Dimension.temperature()>:
  Qty{value}

def moles(value: F32) -> Quantity<Dimension.amount()>:
  Qty{value}

def candela(value: F32) -> Quantity<Dimension.luminosity()>:
  Qty{value}

def value(-D: Dimension, quantity: Quantity<D>) -> F32:
  match quantity:
    case Qty{v}:
      v

def add(-D: Dimension, a: Quantity<D>, b: Quantity<D>) -> Quantity<D>:
  match a b:
    case Qty{a} Qty{b}:
      Qty{(a + b : F32)}

def scale(-D: Dimension, factor: F32, quantity: Quantity<D>) -> Quantity<D>:
  match quantity:
    case Qty{v}:
      Qty{(factor * v : F32)}

def multiply(
  -A: Dimension,
  -B: Dimension,
  a: Quantity<A>,
  b: Quantity<B>
) -> Quantity<Dimension.multiply(A, B)>:
  match a b:
    case Qty{a} Qty{b}:
      Qty{(a * b : F32)}

def divide(
  -A: Dimension,
  -B: Dimension,
  a: Quantity<A>,
  b: Quantity<B>
) -> Quantity<Dimension.divide(A, B)>:
  match a b:
    case Qty{a} Qty{b}:
      Qty{(a / b : F32)}

def speed(
  distance: Quantity<Dimension.length()>,
  elapsed: Quantity<Dimension.time()>
) -> Quantity<Dimension.speed()>:
  divide(Dimension.length(), Dimension.time(), distance, elapsed)

def acceleration(
  velocity: Quantity<Dimension.speed()>,
  elapsed: Quantity<Dimension.time()>
) -> Quantity<Dimension.acceleration()>:
  divide(Dimension.speed(), Dimension.time(), velocity, elapsed)

def force(
  mass: Quantity<Dimension.mass()>,
  acceleration: Quantity<Dimension.acceleration()>
) -> Quantity<Dimension.force()>:
  multiply(Dimension.mass(), Dimension.acceleration(), mass, acceleration)

def energy(
  force: Quantity<Dimension.force()>,
  distance: Quantity<Dimension.length()>
) -> Quantity<Dimension.energy()>:
  multiply(Dimension.force(), Dimension.length(), force, distance)

def kinetic_energy(
  mass: Quantity<Dimension.mass()>,
  +velocity: Quantity<Dimension.speed()>
) -> Quantity<Dimension.energy()>:
  velocity_squared = multiply(
    Dimension.speed(),
    Dimension.speed(),
    velocity,
    velocity
  )
  mass_velocity_squared = multiply(
    Dimension.mass(),
    Dimension.multiply(Dimension.speed(), Dimension.speed()),
    mass,
    velocity_squared
  )
  scale(Dimension.energy(), 0.5, mass_velocity_squared)

def show(-D: Dimension, unit: String, quantity: Quantity<D>) -> String:
  F32.show(value(D, quantity)) ++ " " ++ unit
