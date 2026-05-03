/** @schema 2.10
 * @input size: number = 24
 * @input color: color = #E87A2E
 * @input opacity: number = 0.7
 */
const s = pencil.input.size;
const c = pencil.input.color;
const op = pencil.input.opacity;
const w = pencil.width;
const h = pencil.height;
return [
  { type: "rectangle", x: 0, y: 0, width: s, height: 3, fill: c, opacity: op },
  { type: "rectangle", x: 0, y: 0, width: 3, height: s, fill: c, opacity: op },
  { type: "rectangle", x: w - s, y: 0, width: s, height: 3, fill: c, opacity: op },
  { type: "rectangle", x: w - 3, y: 0, width: 3, height: s, fill: c, opacity: op },
  { type: "rectangle", x: 0, y: h - 3, width: s, height: 3, fill: c, opacity: op },
  { type: "rectangle", x: 0, y: h - s, width: 3, height: s, fill: c, opacity: op },
  { type: "rectangle", x: w - s, y: h - 3, width: s, height: 3, fill: c, opacity: op },
  { type: "rectangle", x: w - 3, y: h - s, width: 3, height: s, fill: c, opacity: op },
];
