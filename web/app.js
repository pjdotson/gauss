import Gauss from "../src/workbook.bend";
import Exact from "../src/exact.bend";

const DEFAULT_SOURCE = `distance = 100 km
elapsed = 60 min
mass = 1500 kg
speed = distance / elapsed
energy = 0.5 * mass * speed ** 2`;
const SCALES = new Map(Object.entries({
  "1":[1n,1n],m:[1n,1n],km:[1000n,1n],ft:[3048n,10000n],in:[254n,10000n],s:[1n,1n],min:[60n,1n],h:[3600n,1n],
  kg:[1n,1n],lb:[45359237n,100000000n],g:[1n,1000n],t:[1000n,1n],A:[1n,1n],deltaK:[1n,1n],deltaC:[1n,1n],mol:[1n,1n],cd:[1n,1n],
  "m/s":[1n,1n],"km/h":[5n,18n],Hz:[1n,1n],N:[1n,1n],kN:[1000n,1n],lbf:[44482216n,10000000n],J:[1n,1n],kJ:[1000n,1n],
  Wh:[3600n,1n],kWh:[3600000n,1n],Pa:[1n,1n],kPa:[1000n,1n],MPa:[1000000n,1n],psi:[6894757n,1000n],W:[1n,1n],kW:[1000n,1n],C:[1n,1n],V:[1n,1n],ohm:[1n,1n],
}));
const UNITS = [...SCALES.keys()];
const $ = (selector) => document.querySelector(selector);
const source = $("#source"), lineNumbers = $("#line-numbers"), results = $("#results"), diagnostic = $("#diagnostic");
const resultCount = $("#result-count"), emptyState = $("#empty-state"), saveState = $("#save-state"), fileInput = $("#file-input");
const numericPolicy = $("#numeric-policy"), suggestions = $("#suggestions"), plot = $("#result-plot");
source.value = localStorage.getItem("gauss.worksheet") || DEFAULT_SOURCE;
numericPolicy.value = localStorage.getItem("gauss.numericPolicy") || "f32";
let latest = [];
let incrementalCache = new Map();

const done = (value) => ({ $:"Done", value });
const fail = (error) => ({ $:"Fail", error });
const invalid = (message) => ({ $:"InvalidFormula", message });
function exponentValue(value) { return value.$ === "EZero" ? 0 : (value.$ === "ENeg" ? -1 : 1) * (Number(value.pred) + 1); }
function dimensionParts(d) { return [d.length,d.mass,d.time,d.current,d.temperature,d.amount,d.luminosity].map(exponentValue); }
function dimensionKey(d) { return dimensionParts(d).join(","); }
function dimensionLabel(d) {
  const axes = ["L","M","T","I","Θ","N","J"], supers = {"-":"⁻",0:"⁰",1:"¹",2:"²",3:"³",4:"⁴",5:"⁵",6:"⁶",7:"⁷",8:"⁸",9:"⁹"};
  const power = (n) => String(n).split("").map((x) => supers[x]).join("");
  const terms = dimensionParts(d).map((n,i) => n ? `${axes[i]}${n === 1 ? "" : power(n)}` : null).filter(Boolean);
  return terms.length ? terms.join(" ") : "dimensionless";
}
const preferredUnit = new Map([
  ["0,0,0,0,0,0,0","1"],["1,0,0,0,0,0,0","m"],["0,1,0,0,0,0,0","kg"],["0,0,1,0,0,0,0","s"],
  ["1,0,-1,0,0,0,0","km/h"],["1,1,-2,0,0,0,0","N"],["2,1,-2,0,0,0,0","kJ"],["-1,1,-2,0,0,0,0","Pa"],
  ["2,1,-3,0,0,0,0","W"],["0,0,0,1,0,0,0","A"],["0,0,0,0,1,0,0","deltaK"],
]);

function gcd(a,b) { while (b) [a,b] = [b,a%b]; return a < 0n ? -a : a; }
function reduced(r) { const d = gcd(r.numerator,r.denominator); return {negative:r.numerator === 0n ? false:r.negative,numerator:r.numerator/d,denominator:r.denominator/d}; }
function rationalText(input) {
  const r = reduced(input), sign = r.negative ? "-":""; let denominator = r.denominator, twos = 0, fives = 0;
  while (denominator % 2n === 0n) { denominator/=2n; twos++; }
  while (denominator % 5n === 0n) { denominator/=5n; fives++; }
  const places = Math.max(twos,fives);
  if (denominator !== 1n || places > 18) return `${sign}${r.numerator}/${r.denominator}`;
  const scaled = r.numerator * 2n**BigInt(places-twos) * 5n**BigInt(places-fives);
  if (!places) return `${sign}${scaled}`;
  const digits = scaled.toString().padStart(places+1,"0");
  return `${sign}${digits.slice(0,-places)}.${digits.slice(-places).replace(/0+$/,"") || "0"}`;
}
const makeRational = (negative,numerator,denominator=1n) => Exact["Rational.make"](negative,numerator,denominator);
const negate = (r) => makeRational(r.numerator === 0n ? false:!r.negative,r.numerator,r.denominator);
function decimalRational(text) {
  const match = text.match(/^([0-9]+)(?:\.([0-9]*))?(?:[eE]([+-]?[0-9]+))?$/);
  if (!match) throw invalid(`Invalid number “${text}”`);
  const fraction = match[2] || "", exponent = Number(match[3] || 0)-fraction.length, coefficient = BigInt(match[1]+fraction);
  return exponent >= 0 ? makeRational(false,coefficient*10n**BigInt(exponent)) : makeRational(false,coefficient,10n**BigInt(-exponent));
}
function formatQuantity(quantity,policy) {
  const unitName = preferredUnit.get(dimensionKey(quantity.dimension));
  if (policy === "exact") {
    let value = quantity.rational;
    if (unitName) { const [n,d] = SCALES.get(unitName), q = Exact["Rational.divide"](value,makeRational(false,n,d)); if (q.$ === "Done") value=q.value; }
    return `${rationalText(value)}${unitName === "1" ? "":` ${unitName || "SI"}`}`;
  }
  if (!unitName) return `${quantity.value} SI`;
  const unit = Gauss["runtime.UnitRegistry.get"](unitName);
  if (unit.$ === "Fail") return `${quantity.value} SI`;
  const formatted = Gauss["runtime.RuntimeUnit.format"](unit.value,quantity);
  return formatted.$ === "Done" ? formatted.value.trim():`${quantity.value} SI`;
}
function describeError(error) {
  const messages = {DivisionByZero:"Division by zero",NegativeSquareRoot:"Square root input must be non-negative",InvalidRoot:"The requested root does not match the input dimension"};
  if (messages[error.$]) return messages[error.$];
  if (error.$ === "DimensionMismatch") return `Dimension mismatch: ${dimensionLabel(error.left)} and ${dimensionLabel(error.right)}`;
  if (error.$ === "UnknownUnit") return `Unknown unit “${error.name}”`;
  if (error.$ === "UnknownCell") return `Unknown quantity “${error.name}”`;
  if (error.$ === "CycleDetected") return `Dependency cycle through “${error.name}”`;
  if (error.$ === "InvalidNumber") return `Invalid number “${error.text}”`;
  return error.message || "Calculation failed";
}

function tokenize(text) {
  const tokens=[]; let index=0;
  while (index < text.length) {
    const rest=text.slice(index), whitespace=rest.match(/^\s+/); if (whitespace) { index+=whitespace[0].length; continue; }
    const number=rest.match(/^(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?/);
    if (number) { tokens.push({type:"number",text:number[0]}); index+=number[0].length; continue; }
    const identifier=rest.match(/^[A-Za-z_][A-Za-z0-9_]*/);
    if (identifier) { tokens.push({type:"identifier",text:identifier[0]}); index+=identifier[0].length; continue; }
    const operator=rest.match(/^(?:\*\*|[+\-*/()])/);
    if (operator) { tokens.push({type:operator[0],text:operator[0]}); index+=operator[0].length; continue; }
    throw invalid(`Unexpected character “${rest[0]}”`);
  }
  tokens.push({type:"end",text:""}); return tokens;
}
function parseExpression(text) {
  const tokens=tokenize(text); let current=0;
  const peek=(type)=>tokens[current].type===type;
  const take=(type,message)=>{ if (!peek(type)) throw invalid(message || `Expected “${type}”`); return tokens[current++]; };
  function primary() {
    if (peek("number")) {
      const number=take("number").text; let unit="1";
      if (peek("identifier")) {
        const first=tokens[current].text, compound=tokens[current+1]?.type==="/"&&tokens[current+2]?.type==="identifier" ? `${first}/${tokens[current+2].text}`:null;
        if (compound && SCALES.has(compound)) { unit=compound; current+=3; } else if (SCALES.has(first)) { unit=first; current++; }
        else throw invalid(`Unknown unit “${first}”`);
      }
      return {type:"literal",number,unit};
    }
    if (peek("identifier")) return {type:"reference",name:take("identifier").text};
    if (peek("(")) { take("("); const value=addSubtract(); take(")","Expected a closing parenthesis"); return value; }
    throw invalid(`Expected a number, quantity name, or parenthesized expression near “${tokens[current].text}”`);
  }
  function power() { let value=primary(); if (peek("**")) { take("**"); value={type:"binary",operator:"**",left:value,right:unary()}; } return value; }
  function unary() { if (peek("+")||peek("-")) { const operator=tokens[current++].type; return {type:"unary",operator,value:unary()}; } return power(); }
  function multiplyDivide() { let value=unary(); while (peek("*")||peek("/")) { const operator=tokens[current++].type; value={type:"binary",operator,left:value,right:unary()}; } return value; }
  function addSubtract() { let value=multiplyDivide(); while (peek("+")||peek("-")) { const operator=tokens[current++].type; value={type:"binary",operator,left:value,right:multiplyDivide()}; } return value; }
  const value=addSubtract(); if (!peek("end")) throw invalid(`Unexpected token “${tokens[current].text}”`); return value;
}
function parseWorksheet(text) {
  const definitions=new Map();
  for (const [index,original] of text.split("\n").entries()) {
    const line=original.replace(/#.*$/,"").trim(); if (!line) continue;
    const equals=line.indexOf("="); if (equals<0) throw invalid(`Line ${index+1}: expected “name = expression”`);
    const name=line.slice(0,equals).trim(), formula=line.slice(equals+1).trim();
    if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(name)) throw invalid(`Line ${index+1}: invalid quantity name “${name}”`);
    if (definitions.has(name)) throw invalid(`Line ${index+1}: “${name}” is already defined`);
    if (!formula) throw invalid(`Line ${index+1}: “${name}” has no expression`);
    try { definitions.set(name,{expression:parseExpression(formula),formula}); } catch (error) { throw invalid(`Line ${index+1}: ${describeError(error)}`); }
  }
  return definitions;
}
function literalValue(node,policy) {
  const unit=Gauss["runtime.UnitRegistry.get"](node.unit); if (unit.$ === "Fail") return unit;
  if (policy === "f32") { const value=Number(node.number); return Number.isFinite(value) ? done(Gauss["runtime.RuntimeUnit.quantity"](unit.value,value)):fail({$:"InvalidNumber",text:node.number}); }
  const [n,d]=SCALES.get(node.unit), rational=Exact["Rational.multiply"](decimalRational(node.number),makeRational(false,n,d));
  return done({dimension:unit.value.dimension,rational});
}
function integerExponent(quantity,policy) {
  if (dimensionKey(quantity.dimension) !== "0,0,0,0,0,0,0") return null;
  if (policy === "f32") return Number.isInteger(quantity.value)&&quantity.value>=0 ? BigInt(quantity.value):null;
  const value=reduced(quantity.rational); return !value.negative&&value.denominator===1n ? value.numerator:null;
}
function exactPower(quantity,exponent) {
  let value=makeRational(false,1n), factor=quantity.rational, remaining=exponent;
  while (remaining>0n) { if (remaining%2n===1n) value=Exact["Rational.multiply"](value,factor); remaining/=2n; if (remaining) factor=Exact["Rational.multiply"](factor,factor); }
  return {dimension:Gauss["gauss.Dimension.pow"](quantity.dimension,exponent),rational:value};
}
function evaluateExpression(node,resolve,policy) {
  if (node.type === "literal") return literalValue(node,policy);
  if (node.type === "reference") return resolve(node.name);
  if (node.type === "unary") { const result=evaluateExpression(node.value,resolve,policy); if (result.$==="Fail"||node.operator==="+") return result; return done(policy==="exact"?{dimension:result.value.dimension,rational:negate(result.value.rational)}:{$:"Dynamic",dimension:result.value.dimension,value:-result.value.value}); }
  const left=evaluateExpression(node.left,resolve,policy); if (left.$==="Fail") return left;
  const right=evaluateExpression(node.right,resolve,policy); if (right.$==="Fail") return right;
  if (node.operator === "**") { const exponent=integerExponent(right.value,policy); if (exponent===null||exponent>10000n) return fail(invalid("Exponent must be a non-negative integer no greater than 10000")); return done(policy==="exact"?exactPower(left.value,exponent):Gauss["runtime.Dynamic.power"](left.value,exponent)); }
  if (policy === "f32") {
    if (node.operator === "+") return Gauss["runtime.Dynamic.add"](left.value,right.value);
    if (node.operator === "-") return Gauss["runtime.Dynamic.subtract"](left.value,right.value);
    if (node.operator === "*") return done(Gauss["runtime.Dynamic.multiply"](left.value,right.value));
    return Gauss["runtime.Dynamic.divide"](left.value,right.value);
  }
  if ((node.operator==="+"||node.operator==="-")&&dimensionKey(left.value.dimension)!==dimensionKey(right.value.dimension)) return fail({$:"DimensionMismatch",left:left.value.dimension,right:right.value.dimension});
  if (node.operator==="+"||node.operator==="-") return done({dimension:left.value.dimension,rational:Exact["Rational.add"](left.value.rational,node.operator==="-"?negate(right.value.rational):right.value.rational)});
  if (node.operator==="*") return done({dimension:Gauss["gauss.Dimension.multiply"](left.value.dimension,right.value.dimension),rational:Exact["Rational.multiply"](left.value.rational,right.value.rational)});
  const quotient=Exact["Rational.divide"](left.value.rational,right.value.rational);
  return quotient.$==="Fail" ? quotient:done({dimension:Gauss["gauss.Dimension.divide"](left.value.dimension,right.value.dimension),rational:quotient.value});
}
function references(node, names=[]) {
  if (node.type === "reference") names.push(node.name);
  if (node.type === "unary") references(node.value,names);
  if (node.type === "binary") { references(node.left,names); references(node.right,names); }
  return names;
}
function evaluateWorksheet(definitions,policy) {
  const cache=new Map(), active=new Set(), signatures=new Map(), signaturePath=new Set(), nextIncremental=new Map();
  const signature=(name)=>{
    if (!definitions.has(name)) return `missing:${name}`;
    if (signatures.has(name)) return signatures.get(name);
    if (signaturePath.has(name)) return `cycle:${name}`;
    signaturePath.add(name);
    const definition=definitions.get(name);
    const value=`${policy}|${definition.formula}|${references(definition.expression).map(signature).join("|")}`;
    signaturePath.delete(name); signatures.set(name,value); return value;
  };
  const resolve=(name)=>{
    if (cache.has(name)) return cache.get(name);
    if (!definitions.has(name)) return fail({$:"UnknownCell",name});
    if (active.has(name)) return fail({$:"CycleDetected",name});
    const version=signature(name), previous=incrementalCache.get(name);
    if (previous?.version===version) { cache.set(name,previous.evaluation); nextIncremental.set(name,previous); return previous.evaluation; }
    active.add(name); const result=evaluateExpression(definitions.get(name).expression,resolve,policy); active.delete(name);
    cache.set(name,result); nextIncremental.set(name,{version,evaluation:result}); return result;
  };
  const evaluated=[...definitions.keys()].map((name)=>({name,evaluation:resolve(name)}));
  incrementalCache=nextIncremental;
  return evaluated;
}
function row(name,evaluation,policy) {
  const tr=document.createElement("tr"), cells=["name","value","dimension","state"].map(()=>document.createElement("td"));
  cells[0].className="name"; cells[1].className="value"; cells[2].className="dimension"; cells[0].textContent=name;
  if (evaluation.$==="Done") { cells[1].textContent=formatQuantity(evaluation.value,policy); cells[2].textContent=dimensionLabel(evaluation.value.dimension); cells[3].innerHTML='<span class="state">Checked</span>'; }
  else { tr.className="failed"; cells[1].textContent=describeError(evaluation.error); cells[2].textContent="—"; cells[3].innerHTML='<span class="state">Blocked</span>'; }
  tr.append(...cells); return tr;
}
function updateLines() { lineNumbers.textContent=source.value.split("\n").map((_,i)=>i+1).join("\n"); lineNumbers.scrollTop=source.scrollTop; }
function numericMagnitude(quantity,policy) { return policy==="f32"?quantity.value:(quantity.rational.negative?-1:1)*Number(quantity.rational.numerator)/Number(quantity.rational.denominator); }
function drawPlot(evaluations,policy) {
  const values=evaluations.filter((x)=>x.evaluation.$==="Done").map((x)=>({name:x.name,magnitude:numericMagnitude(x.evaluation.value,policy)})).filter((x)=>Number.isFinite(x.magnitude));
  const ratio=window.devicePixelRatio||1,width=Math.max(plot.clientWidth,320),height=150; plot.width=width*ratio; plot.height=height*ratio;
  const context=plot.getContext("2d"); context.scale(ratio,ratio); context.clearRect(0,0,width,height); context.font='10px "SFMono-Regular", Consolas, monospace';
  if (!values.length) { context.fillStyle="#61747e"; context.fillText("No numeric results",14,26); return; }
  const scores=values.map((x)=>Math.log10(Math.abs(x.magnitude)+1)), maximum=Math.max(...scores,1), slot=width/values.length;
  values.forEach(({name,magnitude},i)=>{ const barHeight=Math.max(2,scores[i]/maximum*102),barWidth=Math.max(4,Math.min(34,slot-8)),x=slot*i+(slot-barWidth)/2; context.fillStyle=magnitude<0?"#a32d2d":"#176c91"; context.fillRect(x,118-barHeight,barWidth,barHeight); context.fillStyle="#405862"; context.textAlign="center"; context.fillText(name.length>10?`${name.slice(0,9)}…`:name,slot*i+slot/2,136); });
}
function calculate() {
  const text=source.value.trim(),policy=numericPolicy.value; updateLines(); results.replaceChildren(); diagnostic.classList.remove("error");
  if (!text) { latest=[]; diagnostic.textContent="Enter a definition to begin."; resultCount.textContent="0 quantities"; emptyState.hidden=false; drawPlot([],policy); return; }
  try {
    latest=evaluateWorksheet(parseWorksheet(text),policy); let failures=0;
    for (const item of latest) { if (item.evaluation.$==="Fail") failures++; results.append(row(item.name,item.evaluation,policy)); }
    emptyState.hidden=latest.length>0; resultCount.textContent=`${latest.length} ${latest.length===1?"quantity":"quantities"}`;
    diagnostic.textContent=failures?`${failures} ${failures===1?"quantity needs":"quantities need"} attention.`:`All quantities are dimensionally consistent · ${policy==="exact"?"exact rational":"fast F32"}.`;
    diagnostic.classList.toggle("error",failures>0); drawPlot(latest,policy);
  } catch (error) { latest=[]; diagnostic.textContent=describeError(error); diagnostic.classList.add("error"); resultCount.textContent="0 quantities"; emptyState.hidden=false; drawPlot([],policy); }
  localStorage.setItem("gauss.worksheet",text); localStorage.setItem("gauss.numericPolicy",policy); saveState.textContent="Saved locally"; updateSuggestions();
}
function updateSuggestions() {
  const before=source.value.slice(0,source.selectionStart),prefix=before.match(/[A-Za-z_][A-Za-z0-9_/]*$/)?.[0]||""; let names=[];
  try { names=[...parseWorksheet(source.value).keys()]; } catch {}
  const choices=[...new Set([...names,...UNITS])].filter((name)=>name!==prefix&&(!prefix||name.toLowerCase().startsWith(prefix.toLowerCase()))).slice(0,10);
  suggestions.replaceChildren(...choices.map((choice)=>{ const button=document.createElement("button"); button.type="button"; button.textContent=choice; button.addEventListener("click",()=>{ const end=source.selectionStart; source.setRangeText(choice,end-prefix.length,end,"end"); source.focus(); calculate(); }); return button; }));
}
const csvCell=(value)=>`"${String(value).replaceAll('"','""')}"`;
function download(contents,type,name) { const link=document.createElement("a"); link.href=URL.createObjectURL(new Blob([contents],{type})); link.download=name; link.click(); URL.revokeObjectURL(link.href); }
let timer;
source.addEventListener("input",()=>{ saveState.textContent="Calculating…"; updateLines(); updateSuggestions(); clearTimeout(timer); timer=setTimeout(calculate,160); });
source.addEventListener("click",updateSuggestions); source.addEventListener("keyup",updateSuggestions); source.addEventListener("scroll",updateLines);
window.addEventListener("resize",()=>drawPlot(latest,numericPolicy.value)); numericPolicy.addEventListener("change",calculate); $("#run-button").addEventListener("click",calculate);
$("#open-button").addEventListener("click",()=>fileInput.click()); $("#save-button").addEventListener("click",()=>download(source.value,"text/plain","worksheet.gauss"));
$("#csv-button").addEventListener("click",()=>{ const policy=numericPolicy.value,lines=[["name","value","SI dimension","state"],...latest.map(({name,evaluation})=>evaluation.$==="Done"?[name,formatQuantity(evaluation.value,policy),dimensionLabel(evaluation.value.dimension),"checked"]:[name,describeError(evaluation.error),"","blocked"])].map((fields)=>fields.map(csvCell).join(",")); download(`${lines.join("\n")}\n`,"text/csv","gauss-results.csv"); });
fileInput.addEventListener("change",async()=>{ const [file]=fileInput.files; if (!file) return; source.value=await file.text(); calculate(); fileInput.value=""; });
calculate();
