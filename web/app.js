import Gauss from "../src/workbook.bend";

const DEFAULT_SOURCE = `distance = 100 km
elapsed = 60 min
mass = 1500 kg
speed = distance / elapsed
speed2 = speed * speed
mass_speed2 = mass * speed2
half = 0.5 1
energy = half * mass_speed2`;

const source = document.querySelector("#source");
const lineNumbers = document.querySelector("#line-numbers");
const results = document.querySelector("#results");
const diagnostic = document.querySelector("#diagnostic");
const resultCount = document.querySelector("#result-count");
const emptyState = document.querySelector("#empty-state");
const saveState = document.querySelector("#save-state");
const fileInput = document.querySelector("#file-input");

source.value = localStorage.getItem("gauss.worksheet") || DEFAULT_SOURCE;

function exponentValue(exponent) {
  if (exponent.$ === "EZero") return 0;
  const magnitude = Number(exponent.pred) + 1;
  return exponent.$ === "ENeg" ? -magnitude : magnitude;
}

function dimensionParts(dimension) {
  return [
    exponentValue(dimension.length),
    exponentValue(dimension.mass),
    exponentValue(dimension.time),
    exponentValue(dimension.current),
    exponentValue(dimension.temperature),
    exponentValue(dimension.amount),
    exponentValue(dimension.luminosity),
  ];
}

function dimensionKey(dimension) {
  return dimensionParts(dimension).join(",");
}

function dimensionLabel(dimension) {
  const axes = ["L", "M", "T", "I", "Θ", "N", "J"];
  const superscripts = { "-": "⁻", 0: "⁰", 1: "¹", 2: "²", 3: "³", 4: "⁴", 5: "⁵", 6: "⁶", 7: "⁷", 8: "⁸", 9: "⁹" };
  const exponent = (value) => String(value).split("").map((part) => superscripts[part]).join("");
  const terms = dimensionParts(dimension)
    .map((value, index) => value === 0 ? null : `${axes[index]}${value === 1 ? "" : exponent(value)}`)
    .filter(Boolean);
  return terms.length ? terms.join(" ") : "dimensionless";
}

const preferredUnit = new Map([
  ["0,0,0,0,0,0,0", "1"],
  ["1,0,0,0,0,0,0", "m"],
  ["0,1,0,0,0,0,0", "kg"],
  ["0,0,1,0,0,0,0", "s"],
  ["1,0,-1,0,0,0,0", "km/h"],
  ["1,1,-2,0,0,0,0", "N"],
  ["2,1,-2,0,0,0,0", "kJ"],
  ["-1,1,-2,0,0,0,0", "Pa"],
  ["2,1,-3,0,0,0,0", "W"],
  ["0,0,0,1,0,0,0", "A"],
  ["0,0,0,0,1,0,0", "deltaK"],
]);

function formatQuantity(quantity) {
  const unitName = preferredUnit.get(dimensionKey(quantity.dimension));
  if (!unitName) return `${quantity.value}`;
  const unit = Gauss["runtime.UnitRegistry.get"](unitName);
  if (unit.$ === "Fail") return `${quantity.value}`;
  const formatted = Gauss["runtime.RuntimeUnit.format"](unit.value, quantity);
  return formatted.$ === "Done" ? formatted.value.trim() : `${quantity.value}`;
}

function describeError(error) {
  switch (error.$) {
    case "DivisionByZero": return "Division by zero";
    case "DimensionMismatch": return `Dimension mismatch: ${dimensionLabel(error.left)} and ${dimensionLabel(error.right)}`;
    case "UnknownUnit": return `Unknown unit “${error.name}”`;
    case "UnknownCell": return `Unknown quantity “${error.name}”`;
    case "CycleDetected": return `Dependency cycle through “${error.name}”`;
    case "InvalidNumber": return `Invalid number “${error.text}”`;
    case "InvalidFormula": return error.message;
    case "NegativeSquareRoot": return "Square root input must be non-negative";
    case "InvalidRoot": return "The requested root does not match the input dimension";
    default: return "Calculation failed";
  }
}

function namesFromSource(text) {
  const seen = new Set();
  return text.split("\n").flatMap((line) => {
    const name = line.trim().split(/\s+/)[0];
    if (!name || seen.has(name)) return [];
    seen.add(name);
    return [name];
  });
}

function row(name, evaluation) {
  const tr = document.createElement("tr");
  const nameCell = document.createElement("td");
  const valueCell = document.createElement("td");
  const dimensionCell = document.createElement("td");
  const stateCell = document.createElement("td");
  nameCell.className = "name";
  valueCell.className = "value";
  dimensionCell.className = "dimension";
  nameCell.textContent = name;
  if (evaluation.$ === "Done") {
    valueCell.textContent = formatQuantity(evaluation.value);
    dimensionCell.textContent = dimensionLabel(evaluation.value.dimension);
    stateCell.innerHTML = '<span class="state">Checked</span>';
  } else {
    tr.className = "failed";
    valueCell.textContent = describeError(evaluation.error);
    dimensionCell.textContent = "—";
    stateCell.innerHTML = '<span class="state">Blocked</span>';
  }
  tr.append(nameCell, valueCell, dimensionCell, stateCell);
  return tr;
}

function updateLines() {
  const count = source.value.split("\n").length;
  lineNumbers.textContent = Array.from({ length: count }, (_, index) => index + 1).join("\n");
  lineNumbers.scrollTop = source.scrollTop;
}

function calculate() {
  const text = source.value.trim();
  updateLines();
  results.replaceChildren();
  diagnostic.classList.remove("error");
  if (!text) {
    diagnostic.textContent = "Enter a definition to begin.";
    resultCount.textContent = "0 quantities";
    emptyState.hidden = false;
    return;
  }
  const parsed = Gauss["Workbook.parse"](text);
  if (parsed.$ === "Fail") {
    diagnostic.textContent = describeError(parsed.error);
    diagnostic.classList.add("error");
    resultCount.textContent = "0 quantities";
    emptyState.hidden = false;
    return;
  }
  const names = namesFromSource(text);
  let failures = 0;
  for (const name of names) {
    const evaluation = Gauss["Workbook.evaluate"](parsed.value, name);
    if (evaluation.$ === "Fail") failures += 1;
    results.append(row(name, evaluation));
  }
  emptyState.hidden = names.length > 0;
  resultCount.textContent = `${names.length} ${names.length === 1 ? "quantity" : "quantities"}`;
  diagnostic.textContent = failures
    ? `${failures} ${failures === 1 ? "quantity needs" : "quantities need"} attention.`
    : "All quantities are dimensionally consistent.";
  diagnostic.classList.toggle("error", failures > 0);
  localStorage.setItem("gauss.worksheet", text);
  saveState.textContent = "Saved locally";
}

let timer;
source.addEventListener("input", () => {
  saveState.textContent = "Calculating…";
  updateLines();
  clearTimeout(timer);
  timer = setTimeout(calculate, 160);
});
source.addEventListener("scroll", updateLines);
document.querySelector("#run-button").addEventListener("click", calculate);
document.querySelector("#open-button").addEventListener("click", () => fileInput.click());
document.querySelector("#save-button").addEventListener("click", () => {
  const blob = new Blob([source.value], { type: "text/plain" });
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = "worksheet.gauss";
  link.click();
  URL.revokeObjectURL(link.href);
});
fileInput.addEventListener("change", async () => {
  const [file] = fileInput.files;
  if (!file) return;
  source.value = await file.text();
  calculate();
  fileInput.value = "";
});

calculate();
