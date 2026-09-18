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
- Structured calculation errors cover zero division, invalid roots, dimension
  mismatches, unknown units and cells, malformed formulas, and dependency cycles.
- Integer powers and checked square roots compose dimensions canonically.
- Runtime-tagged quantities power a named-cell formula engine and text worksheet
  parser without giving up dimensional checks.
- An arbitrary-precision rational kernel is available for calculations that
  must remain exact until an explicit `F32` conversion boundary.
- The browser worksheet supports normal infix expressions with precedence,
  parentheses, unary signs, integer powers, and formulas such as
  `energy = 0.5 * mass * speed ** 2`.
- Browser calculations can use fast `F32` values or arbitrary-precision exact
  rationals. Dependencies are memoized across edits, so unchanged branches are
  reused during recalculation.
- Unit-aware suggestions, live diagnostics, a result-magnitude plot, CSV export,
  local persistence, and `.gauss` file import/export are built in.
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

## Text worksheets

`src/workbook.bend` parses a deliberately small, auditable grammar:

```text
distance = 100 km
elapsed = 60 min
speed = distance / elapsed
```

Definitions may be quantity literals or binary formulas using `+`, `-`, `*`,
and `/`. References may appear before their definitions. Evaluation detects
unknown cells, incompatible addition and subtraction, division by zero, and
cycles in the dependency graph.

Run the command-line worksheet example with:

```sh
bend worksheet.bend
```

## Browser worksheet

The browser UI uses the Bend dimension, runtime-quantity, and exact-rational
kernels directly. Its editor adds a richer expression parser around those
checked operations. Build and serve it locally with:

```sh
bend web/index.html -o dist
python3 -m http.server --directory dist
```

The worksheet autosaves in browser storage and can open or save plain-text
`.gauss` documents. Operators follow normal precedence and include `+`, `-`,
`*`, `/`, and `**`; parentheses and unary `+`/`-` are supported. Powers must be
non-negative dimensionless integers.

## Run it

Install Bend, then check the proofs and run the example:

```sh
curl -fsSL https://bend-lang.com/install.sh | sh
bend PROOF.bend
bend main.bend
bend worksheet.bend
```

## Direction

The next useful milestones are broader unit coverage, uncertainty and
significant-figure propagation, parameter sweeps, and shareable hosted
documents. See [ROADMAP.md](ROADMAP.md).

## License

MIT
