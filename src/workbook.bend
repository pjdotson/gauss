import Base
import ./runtime.bend as Runtime

type Operator is Data:
  Add{}
  Subtract{}
  Multiply{}
  Divide{}

def Operator.map() -> Map<&2, Operator>:
  map = Map.new(&2, Operator)
  map = Map.set(&2, Operator, map, "+", Add{})
  map = Map.set(&2, Operator, map, "-", Subtract{})
  map = Map.set(&2, Operator, map, "*", Multiply{})
  Map.set(&2, Operator, map, "/", Divide{})

def Operator.get.value(pair: Map<&2, Operator> & Operator) ->
  Result<&2, &2, Runtime.CalcError, Operator>:
  (map, operator) = pair
  Done{operator}

def Operator.get.if(name: String, pair: Map<&2, Operator> & Bool) ->
  Result<&2, &2, Runtime.CalcError, Operator>:
  (map, found) = pair
  match found:
    case True{}:
      Operator.get.value(Map.get(Operator, Add{}, map, name))
    case False{}:
      Fail{Runtime.InvalidFormula{"unknown operator: " ++ name}}

def Operator.get(+name: String) -> Result<&2, &2, Runtime.CalcError, Operator>:
  Operator.get.if(name, Map.has(&2, Operator, Operator.map(), name))

type Expression is Data:
  Literal{displayed: F32, unit: String}
  Binary{left: String, operator: Operator, right: String}

type Cell is Data:
  Cell{name: String, expression: Expression, source: String}

type Workbook is Data:
  Workbook{cells: Map<&2, Cell>, source: String}

def Parser.number(
  name: String,
  +number: String,
  unit: String,
  source: String,
  parsed: Maybe<&2, F32>
) -> Result<&2, &2, Runtime.CalcError, Cell>:
  match parsed:
    case Some{value}:
      Done{Cell{name, Literal{value, unit}, source}}
    case None{}:
      Fail{Runtime.InvalidNumber{number}}

def Parser.literal(
  name: String,
  +number: String,
  unit: String,
  source: String,
  assignment: Bool
) -> Result<&2, &2, Runtime.CalcError, Cell>:
  match assignment:
    case True{}:
      Parser.number(name, number, unit, source, F32.read(number))
    case False{}:
      Fail{Runtime.InvalidFormula{"expected: name = value unit"}}

def Parser.binary.operator(
  name: String,
  left: String,
  right: String,
  source: String,
  parsed: Result<&2, &2, Runtime.CalcError, Operator>
) -> Result<&2, &2, Runtime.CalcError, Cell>:
  match parsed:
    case Fail{error}:
      Fail{error}
    case Done{operator}:
      Done{Cell{name, Binary{left, operator, right}, source}}

def Parser.binary(
  name: String,
  left: String,
  operator: String,
  right: String,
  source: String,
  assignment: Bool
) -> Result<&2, &2, Runtime.CalcError, Cell>:
  match assignment:
    case True{}:
      Parser.binary.operator(name, left, right, source, Operator.get(operator))
    case False{}:
      Fail{Runtime.InvalidFormula{"expected: name = left operator right"}}

def Parser.tokens(
  source: String,
  tokens: List<&2, String>
) -> Result<&2, &2, Runtime.CalcError, Cell>:
  match tokens:
    case name <> assignment <> number <> unit <> Nil{}:
      Parser.literal(name, number, unit, source, String.eq(assignment, "="))
    case name <> assignment <> left <> operator <> right <> Nil{}:
      Parser.binary(
        name, left, operator, right, source, String.eq(assignment, "=")
      )
    case tokens:
      Fail{Runtime.InvalidFormula{
        "use 'name = value unit' or 'name = left operator right'"
      }}

def Parser.line(+source: String) -> Result<&2, &2, Runtime.CalcError, Cell>:
  Parser.tokens(source, String.split(String.trim(source), ' '))

type ParseState is Data:
  ParseLines{lines: List<&2, String>, cells: Map<&2, Cell>}
  ParseCell{
    rest: List<&2, String>,
    cells: Map<&2, Cell>,
    parsed: Result<&2, &2, Runtime.CalcError, Cell>
  }

def Parser.run(fuel: Nat, state: ParseState) ->
  Result<&2, &2, Runtime.CalcError, Map<&2, Cell>>:
  match fuel state:
    case 0n state:
      Fail{Runtime.InvalidFormula{"parser fuel exhausted"}}
    case 1n+fuel ParseLines{Nil{}, cells}:
      Done{cells}
    case 1n+fuel ParseLines{line <> rest, cells}:
      Parser.run(fuel, ParseCell{rest, cells, Parser.line(line)})
    case 1n+fuel ParseCell{rest, cells, Fail{error}}:
      Fail{error}
    case 1n+fuel ParseCell{rest, cells, Done{Cell{+name, expression, source}}}:
      updated = Map.set(
        &2, Cell, cells, name, Cell{name, expression, source}
      )
      Parser.run(fuel, ParseLines{rest, updated})

def Workbook.parse.finish(
  source: String,
  parsed: Result<&2, &2, Runtime.CalcError, Map<&2, Cell>>
) -> Result<&2, &2, Runtime.CalcError, Workbook>:
  match parsed:
    case Fail{error}:
      Fail{error}
    case Done{cells}:
      Done{Workbook{cells, source}}

def Workbook.parse(+source: String) ->
  Result<&2, &2, Runtime.CalcError, Workbook>:
  +lines = String.lines(String.trim(source))
  Workbook.parse.finish(
    source,
    Parser.run(
      1n+Nat.mul(2n, List.length(&2, String, lines)),
      ParseLines{lines, Map.new(&2, Cell)}
    )
  )

def Workbook.serialize(workbook: Workbook) -> String:
  match workbook:
    case Workbook{cells, source}:
      source

def Workbook.size(workbook: Workbook) -> Nat:
  match workbook:
    case Workbook{cells, source}:
      Map.size(&2, Cell, cells)

def Workbook.eval.binary.results(
  left: Result<&2, &2, Runtime.CalcError, Runtime.DynamicQuantity>,
  right: Result<&2, &2, Runtime.CalcError, Runtime.DynamicQuantity>,
  operator: Operator
) -> Result<&2, &2, Runtime.CalcError, Runtime.DynamicQuantity>:
  match left right:
    case Fail{error} right:
      Fail{error}
    case Done{left} Fail{error}:
      Fail{error}
    case Done{left} Done{right}:
      match operator:
        case Add{}:
          Runtime.Dynamic.add(left, right)
        case Subtract{}:
          Runtime.Dynamic.subtract(left, right)
        case Multiply{}:
          Done{Runtime.Dynamic.multiply(left, right)}
        case Divide{}:
          Runtime.Dynamic.divide(left, right)

def Workbook.has_cell(workbook: Workbook, name: String) -> Map<&2, Cell> & Bool:
  match workbook:
    case Workbook{cells, source}:
      Map.has(&2, Cell, cells, name)

type EvalFrame is Data:
  EvaluateRight{operator: Operator, right: String, trail: Set()}
  ApplyOperator{operator: Operator, left: Runtime.DynamicQuantity}

type EvalState is Type:
  EvaluateName{name: String, trail: Set(), stack: List<&2, EvalFrame>}
  CheckCycle{
    name: String,
    stack: List<&2, EvalFrame>,
    checked: Set() & Bool
  }
  LookupCell{
    name: String,
    trail: Set(),
    stack: List<&2, EvalFrame>,
    lookup: Map<&2, Cell> & Bool
  }
  EvaluateCell{
    trail: Set(),
    stack: List<&2, EvalFrame>,
    found: Map<&2, Cell> & Cell
  }
  EvaluateExpression{
    trail: Set(),
    stack: List<&2, EvalFrame>,
    expression: Expression
  }
  ResolveUnit{
    displayed: F32,
    stack: List<&2, EvalFrame>,
    unit: Result<&2, &2, Runtime.CalcError, Runtime.RuntimeUnit>
  }
  Evaluated{
    result: Result<&2, &2, Runtime.CalcError, Runtime.DynamicQuantity>,
    stack: List<&2, EvalFrame>
  }

def Evaluator.run(+fuel: Nat, +workbook: Workbook, state: EvalState) ->
  Result<&2, &2, Runtime.CalcError, Runtime.DynamicQuantity>:
  match fuel state:
    case 0n state:
      Fail{Runtime.InvalidFormula{"evaluation fuel exhausted"}}
    case 1n+fuel EvaluateName{+name, trail, stack}:
      Evaluator.run(
        fuel, workbook,
        CheckCycle{name, stack, Set.has(trail, name)}
      )
    case 1n+fuel CheckCycle{name, stack, (trail, True{})}:
      Fail{Runtime.CycleDetected{name}}
    case 1n+fuel CheckCycle{+name, stack, (trail, False{})}:
      +next_trail = Set.add(trail, name)
      Evaluator.run(
        fuel, workbook,
        LookupCell{
          name, next_trail, stack, Workbook.has_cell(workbook, name)
        }
      )
    case 1n+fuel LookupCell{name, trail, stack, (cells, False{})}:
      Fail{Runtime.UnknownCell{name}}
    case 1n+fuel LookupCell{name, trail, stack, (cells, True{})}:
      default = {Cell{"", Literal{0.0, ""}, ""} : Cell}
      Evaluator.run(
        fuel, workbook,
        EvaluateCell{trail, stack, Map.get(Cell, default, cells, name)}
      )
    case 1n+fuel EvaluateCell{trail, stack, (cells, Cell{name, expression, source})}:
      Evaluator.run(
        fuel, workbook, EvaluateExpression{trail, stack, expression}
      )
    case 1n+fuel EvaluateExpression{trail, stack, Literal{displayed, unit_name}}:
      Evaluator.run(
        fuel, workbook,
        ResolveUnit{displayed, stack, Runtime.UnitRegistry.get(unit_name)}
      )
    case 1n+fuel EvaluateExpression{+trail, stack, Binary{left, operator, right}}:
      Evaluator.run(
        fuel, workbook,
        EvaluateName{left, trail, EvaluateRight{operator, right, trail} <> stack}
      )
    case 1n+fuel ResolveUnit{displayed, stack, Fail{error}}:
      Fail{error}
    case 1n+fuel ResolveUnit{displayed, stack, Done{unit}}:
      Evaluator.run(
        fuel, workbook,
        Evaluated{Done{Runtime.RuntimeUnit.quantity(unit, displayed)}, stack}
      )
    case 1n+fuel Evaluated{Fail{error}, stack}:
      Fail{error}
    case 1n+fuel Evaluated{Done{value}, Nil{}}:
      Done{value}
    case 1n+fuel Evaluated{
      Done{left}, EvaluateRight{operator, right, trail} <> stack
    }:
      Evaluator.run(
        fuel, workbook,
        EvaluateName{right, trail, ApplyOperator{operator, left} <> stack}
      )
    case 1n+fuel Evaluated{
      Done{right}, ApplyOperator{operator, left} <> stack
    }:
      Evaluator.run(
        fuel, workbook,
        Evaluated{
          Workbook.eval.binary.results(Done{left}, Done{right}, operator),
          stack
        }
      )

def Workbook.evaluate(+workbook: Workbook, name: String) ->
  Result<&2, &2, Runtime.CalcError, Runtime.DynamicQuantity>:
  Evaluator.run(
    Nat.mul(16n, 1n+Workbook.size(workbook)),
    workbook,
    EvaluateName{name, Set.new(), Nil{}}
  )
