export const tileAssetRevision = "26e127ba2117f45cdce5ea0225748cc0cfad3169";

const tileAssetBase =
  `https://raw.githubusercontent.com/FluffyStuff/riichi-mahjong-tiles/${tileAssetRevision}/Regular/`;

export const tileFrontAssetUrl = `${tileAssetBase}Front.svg`;

const honorAssetNames = {
  east: "Ton",
  south: "Nan",
  west: "Shaa",
  north: "Pei",
  white: "Haku",
  green: "Hatsu",
  red: "Chun",
};

export function tileAssetUrl(tile) {
  if (honorAssetNames[tile.kind]) {
    return `${tileAssetBase}${honorAssetNames[tile.kind]}.svg`;
  }
  const rank = tile.kind[0];
  const suit = { m: "Man", p: "Pin", s: "Sou" }[tile.kind[1]];
  return `${tileAssetBase}${suit}${rank}${tile.red ? "-Dora" : ""}.svg`;
}
