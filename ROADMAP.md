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
- [ ] More units and temperature scales
- [ ] Structured errors for invalid domains and division by zero

## 0.2 — Formula engine

- [x] General dimension algebra using SI base-dimension exponents
- [ ] Parse formulas and quantity literals such as `12.5 kN`
- [ ] Named cells and dependency graph
- [ ] Cycle detection and incremental recalculation
- [ ] Uncertainty and significant-figure propagation

## 0.3 — Engineering worksheet

- [ ] Browser-based grid and formula editor
- [ ] Unit-aware autocomplete and diagnostics
- [ ] Tables, plots, and parameter sweeps
- [ ] Import/export for CSV and common spreadsheet formats
- [ ] Shareable, reproducible calculation documents
