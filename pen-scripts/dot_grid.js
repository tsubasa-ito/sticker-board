/** @schema 2.10
 * @input dotSize: number = 3
 * @input gap: number = 30
 * @input dotColor: color = #FAF0DE
 * @input opacity: number = 0.25
 */
const nodes = [];
const cols = Math.ceil(pencil.width / pencil.input.gap) + 1;
const rows = Math.ceil(pencil.height / pencil.input.gap) + 1;
for (let r = 0; r < rows; r++) {
  for (let c = 0; c < cols; c++) {
    nodes.push({
      type: "ellipse",
      x: c * pencil.input.gap - pencil.input.dotSize / 2,
      y: r * pencil.input.gap - pencil.input.dotSize / 2,
      width: pencil.input.dotSize,
      height: pencil.input.dotSize,
      fill: pencil.input.dotColor,
      opacity: pencil.input.opacity,
    });
  }
}
return nodes;
