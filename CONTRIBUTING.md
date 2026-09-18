# Contributing

Gauss is an experiment in trustworthy engineering computation. Small issues,
design discussions, new units, formulas, laws, and proof improvements are all
welcome.

Before opening a pull request, run:

```sh
bend PROOF.bend
bend main.bend
bend worksheet.bend
bend src/runtime.bend
bend src/workbook.bend
bend src/exact.bend
bend web/index.html -o dist
```

Keep user-authored requirements in `LAWS.bend`; implementations and their
proofs belong in `src/` and `PROOF.bend`.
