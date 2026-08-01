const tileKindOrder = new Map([
  ...["m", "p", "s"].flatMap((suit) =>
    Array.from({ length: 9 }, (_, index) => `${index + 1}${suit}`),
  ),
  "east",
  "south",
  "west",
  "north",
  "white",
  "green",
  "red",
].map((kind, index) => [kind, index]));

export function compareHandTiles(left, right) {
  const kindDifference =
    (tileKindOrder.get(left.kind) ?? Number.MAX_SAFE_INTEGER) -
    (tileKindOrder.get(right.kind) ?? Number.MAX_SAFE_INTEGER);
  if (kindDifference !== 0) return kindDifference;
  return Number(left.red) - Number(right.red);
}

export function sortHandTiles(tiles) {
  return [...tiles].sort(compareHandTiles);
}
