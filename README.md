# Gauss

Gauss is an experimental, unit-aware calculation engine for engineers, written
in [Bend](https://bend-lang.com/). It explores what a better spreadsheet core
could feel like when physical quantities and formulas are understood by the
type system instead of being stored as unlabelled cells.

> [!IMPORTANT]
> This is a public test project and an early proof of concept, not production
> engineering software.

## What works today

- Physical dimensions are encoded as the seven SI base-dimension exponents, so
  incompatible quantities cannot be passed to a formula accidentally.
- Values are normalized to SI units at construction time.
- Generic multiplication and division derive result dimensions automatically;
  common dimensions include area, volume, speed, acceleration, force, energy,
  frequency, pressure, power, charge, voltage, and resistance.
- Typed formulas cover speed, acceleration, force, work, and kinetic energy.
- Dimension-indexed units provide safe input conversion and output formatting,
  including scaled units and affine temperature scales such as Celsius.
- `LAWS.bend` specifies canonical exponent results and cancellation behavior;
  `PROOF.bend` proves them.
- `main.bend` is a runnable worksheet-style example.

For example, `Gauss.speed` only accepts a length and a time:

```python
distance = Gauss.kilometers(100.0)
elapsed = Gauss.minutes(60.0)
velocity = Gauss.speed(distance, elapsed)
```

Passing a mass where the distance belongs is a compile-time error rather than a
surprising spreadsheet result.

Formatting is checked in the same way:

```python
text = Gauss.format(
  Gauss.Dimension.speed(),
  Gauss.Units.kilometer_per_hour(),
  velocity
)
```

A speed can be displayed in `km/h`, but trying to format energy with that unit
is a compile-time error. Available specifications include SI base units, feet,
pounds, minutes, Celsius, `km/h`, hertz, newtons, joules, kilojoules, pascals,
watts, coulombs, volts, and ohms.

The dimension parameter is erased during compilation. A checked
`Quantity<Dimension.force()>` therefore occupies only the underlying `F32` at
runtime.

## Run it

Install Bend, then check the proofs and run the example:

```sh
curl -fsSL https://bend-lang.com/install.sh | sh
bend PROOF.bend
bend main.bend
```

## Direction

The next useful milestones are broader unit coverage, uncertainty and
significant-figure tracking, a formula/parser layer, named cells and dependency
graphs, and eventually an interactive grid UI. See [ROADMAP.md](ROADMAP.md).

## License

MIT
