import Base
import ./src/runtime.bend as Runtime
import ./src/workbook.bend as Sheet

def Demo.result(
  result: Result<&2, &2, Runtime.CalcError, Runtime.DynamicQuantity>
) -> IO(Unit):
  match result:
    case Fail{error}:
      IO.print("calculation failed")
    case Done{Runtime.Dynamic{dimension, value}}:
      IO.print("energy (SI) = " ++ F32.show(value) ++ " J")

def Demo.workbook(
  result: Result<&2, &2, Runtime.CalcError, Sheet.Workbook>
) -> IO(Unit):
  match result:
    case Fail{error}:
      IO.print("worksheet parse failed")
    case Done{workbook}:
      Demo.result(Sheet.Workbook.evaluate(workbook, "energy"))

def main() -> IO(Unit):
  source =
    "distance = 100 km\n" ++
    "elapsed = 60 min\n" ++
    "mass = 1500 kg\n" ++
    "speed = distance / elapsed\n" ++
    "speed2 = speed * speed\n" ++
    "mass_speed2 = mass * speed2\n" ++
    "half = 0.5 1\n" ++
    "energy = half * mass_speed2"
  Demo.workbook(Sheet.Workbook.parse(source))
