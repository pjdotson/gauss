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

The next useful milestones are safe output conversions, uncertainty and
significant-figure tracking, a formula/parser layer, named cells and dependency
graphs, and eventually an interactive grid UI. See [ROADMAP.md](ROADMAP.md).

## License

MIT
