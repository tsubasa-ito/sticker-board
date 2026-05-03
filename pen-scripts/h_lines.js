/** @schema 2.10
 * @input gap: number = 28
 * @input lineColor: color = #C8A882
 * @input opacity: number = 0.3
 * @input thickness: number = 1
 */
const nodes = [];
const rows = Math.ceil(pencil.height / pencil.input.gap) + 1;
for (let r = 0; r < rows; r++) {
  nodes.push({
    type: "rectangle",
    x: 0,
    y: r * pencil.input.gap,
    width: pencil.width,
    height: pencil.input.thickness,
    fill: pencil.input.lineColor,
    opacity: pencil.input.opacity,
  });
}
return nodes;
