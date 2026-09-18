# Roadmap

Gauss starts with a deliberately small, trustworthy kernel. The long-term goal
is a collaborative engineering notebook with the familiarity of a spreadsheet
and the correctness of a dimensional-analysis tool.

## 0.1 — Quantity kernel

- [x] SI-normalized quantities
- [x] Compile-time seven-axis SI dimension algebra
- [x] Generic dimension multiplication, division, inversion, and cancellation
- [x] Common engineering formulas
- [x] Law-driven behavior checks
- [x] Dimension-safe input conversion and output formatting
- [x] Affine temperature conversion with Celsius
- [x] Separate absolute temperatures from temperature differences
- [x] Integer dimension powers and checked square roots
- [ ] More units and temperature scales
- [x] Structured errors for invalid domains and division by zero
- [x] Arbitrary-precision exact rational quantity kernel
- [x] Integrate selectable numeric policies into worksheets

## 0.2 — Formula engine

- [x] General dimension algebra using SI base-dimension exponents
- [x] Parse formulas and quantity literals such as `12.5 kN`
- [x] Named cells and dependency graph
- [x] Cycle detection
- [x] Incremental recalculation cache
- [x] Parentheses, precedence, integer powers, and unary expressions
- [ ] Worksheet functions such as `sqrt`, `sin`, and `cos`
- [ ] Uncertainty and significant-figure propagation

## 0.3 — Engineering worksheet

- [x] Browser-based worksheet and formula editor
- [x] Unit-aware suggestions and diagnostics
- [x] Result magnitude plot
- [ ] Tables and parameter sweeps
- [x] CSV result export
- [ ] Import/export for common spreadsheet formats
- [x] Local `.gauss` document persistence
- [ ] Shareable hosted calculation documents
