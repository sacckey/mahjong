# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "mahjong @ git+https://github.com/MahjongRepository/mahjong.git@51675182ae0c040a4cb143eb1e109dc06e0a78b2",
# ]
# ///

"""Compare deterministic generated hands with MahjongRepository/mahjong."""

from __future__ import annotations

import argparse
import random
import subprocess
import tempfile
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

from mahjong.constants import EAST
from mahjong.hand_calculating.hand import HandCalculator
from mahjong.hand_calculating.hand_config import HandConfig, OptionalRules
from mahjong.meld import Meld


REFERENCE_COMMIT = "51675182ae0c040a4cb143eb1e109dc06e0a78b2"
ROOT = Path(__file__).resolve().parents[2]
ORPHANS = (0, 8, 9, 17, 18, 26, 27, 28, 29, 30, 31, 32, 33)


@dataclass(frozen=True)
class GroupSpec:
    group_type: str
    tile: int
    meld_kind: str | None = None

    def kinds(self) -> list[int]:
        if self.group_type == "sequence":
            return [self.tile, self.tile + 1, self.tile + 2]
        count = 4 if self.group_type == "quad" else 3
        return [self.tile] * count


@dataclass(frozen=True)
class ContextSpec:
    tsumo: bool
    seat: int
    round: int
    riichi: int
    ippatsu: bool
    haitei: bool
    houtei: bool
    honba: int
    riichi_sticks: int


@dataclass(frozen=True)
class YakuSpec:
    constructor: str
    han: int
    yakuman_multiplier: int


@dataclass(frozen=True)
class ExpectedSpec:
    yaku: tuple[YakuSpec, ...]
    dora: int
    ura_dora: int
    aka_dora: int
    han: int
    fu: int
    limit: str
    base_points: int
    payment: str
    riichi_bonus: int
    winner_gain: int


@dataclass(frozen=True)
class CaseSpec:
    name: str
    concealed: tuple[int, ...]
    winning: int
    melds: tuple[tuple[int, tuple[int, ...]], ...]
    dora_indicators: tuple[int, ...]
    ura_dora_indicators: tuple[int, ...]
    context: ContextSpec
    expected: ExpectedSpec


YAKU_CLASS_TO_CONSTRUCTOR = {
    "Riichi": "Riichi",
    "DaburuRiichi": "DoubleRiichi",
    "Ippatsu": "Ippatsu",
    "Tsumo": "MenzenTsumo",
    "Tanyao": "Tanyao",
    "Pinfu": "Pinfu",
    "Iipeiko": "Iipeikou",
    "SeatWindEast": "SeatWind",
    "SeatWindSouth": "SeatWind",
    "SeatWindWest": "SeatWind",
    "SeatWindNorth": "SeatWind",
    "RoundWindEast": "RoundWind",
    "RoundWindSouth": "RoundWind",
    "RoundWindWest": "RoundWind",
    "RoundWindNorth": "RoundWind",
    "Haku": "WhiteDragon",
    "Hatsu": "GreenDragon",
    "Chun": "RedDragon",
    "Rinshan": "RinshanKaihou",
    "Chankan": "Chankan",
    "Haitei": "HaiteiRaoyue",
    "Houtei": "HouteiRaoyui",
    "Sanshoku": "SanshokuDoujun",
    "Ittsu": "Ittsu",
    "Chantai": "Chanta",
    "Chiitoitsu": "Chiitoitsu",
    "Toitoi": "Toitoi",
    "Sanankou": "Sanankou",
    "Honroto": "Honroutou",
    "SanshokuDoukou": "SanshokuDoukou",
    "SanKantsu": "Sankantsu",
    "Shosangen": "Shousangen",
    "Junchan": "Junchan",
    "Honitsu": "Honitsu",
    "Ryanpeikou": "Ryanpeikou",
    "Chinitsu": "Chinitsu",
    "Tenhou": "Tenhou",
    "Chiihou": "Chiihou",
    "KokushiMusou": "KokushiMusou",
    "DaburuKokushiMusou": "KokushiMusou",
    "Suuankou": "Suuankou",
    "SuuankouTanki": "Suuankou",
    "Daisangen": "Daisangen",
    "Shousuushii": "Shousuushi",
    "DaiSuushii": "Daisuushi",
    "Tsuuiisou": "Tsuuiisou",
    "Ryuuiisou": "Ryuuiisou",
    "Chinroutou": "Chinroutou",
    "ChuurenPoutou": "ChuurenPoutou",
    "DaburuChuurenPoutou": "ChuurenPoutou",
    "Suukantsu": "Suukantsu",
}

BONUS_CLASSES = {
    "Dora": "dora",
    "UraDora": "ura_dora",
    "AkaDora": "aka_dora",
}

YAKU_ORDER = {
    name: index
    for index, name in enumerate(
        (
            "Tenhou",
            "Chiihou",
            "KokushiMusou",
            "Suuankou",
            "Daisangen",
            "Shousuushi",
            "Daisuushi",
            "Suukantsu",
            "Tsuuiisou",
            "Ryuuiisou",
            "Chinroutou",
            "ChuurenPoutou",
            "Riichi",
            "DoubleRiichi",
            "Ippatsu",
            "MenzenTsumo",
            "RinshanKaihou",
            "Chankan",
            "HaiteiRaoyue",
            "HouteiRaoyui",
            "Tanyao",
            "Pinfu",
            "Ryanpeikou",
            "Iipeikou",
            "SeatWind",
            "RoundWind",
            "WhiteDragon",
            "GreenDragon",
            "RedDragon",
            "SanshokuDoujun",
            "Ittsu",
            "Junchan",
            "Chanta",
            "Toitoi",
            "Sanankou",
            "SanshokuDoukou",
            "Sankantsu",
            "Shousangen",
            "Chiitoitsu",
            "Honroutou",
            "Honitsu",
            "Chinitsu",
        )
    )
}

MELD_KIND_NUMBER = {
    "chi": 0,
    "pon": 1,
    "open_kan": 2,
    "closed_kan": 3,
    "added_kan": 4,
}


def random_regular_group(rng: random.Random) -> GroupSpec:
    if rng.random() < 0.64:
        suit = rng.randrange(3)
        start = rng.randrange(7)
        return GroupSpec("sequence", suit * 9 + start)
    return GroupSpec("triplet", rng.randrange(34))


def valid_physical_counts(groups: list[GroupSpec], pair: int) -> bool:
    counts = Counter([pair, pair])
    for group in groups:
        counts.update(group.kinds())
    return max(counts.values()) <= 4


def closed_standard_shape(rng: random.Random, with_kan: bool) -> tuple[list[GroupSpec], int]:
    for _ in range(10_000):
        groups: list[GroupSpec] = []
        kan_index = rng.randrange(4) if with_kan else -1
        for index in range(4):
            if index == kan_index:
                groups.append(GroupSpec("quad", rng.randrange(34), "closed_kan"))
            else:
                groups.append(random_regular_group(rng))
        pair = rng.randrange(34)
        if valid_physical_counts(groups, pair):
            return groups, pair
    raise RuntimeError("could not generate a closed standard hand")


def open_standard_shape(rng: random.Random, with_kan: bool) -> tuple[list[GroupSpec], int]:
    for _ in range(10_000):
        dragon = rng.randrange(31, 34)
        required = (
            GroupSpec("quad", dragon, rng.choice(("open_kan", "added_kan")))
            if with_kan
            else GroupSpec("triplet", dragon, "pon")
        )
        groups = [required]
        for _ in range(3):
            group = random_regular_group(rng)
            if rng.random() < 0.48:
                meld_kind = "chi" if group.group_type == "sequence" else "pon"
                group = GroupSpec(group.group_type, group.tile, meld_kind)
            groups.append(group)
        pair = rng.randrange(34)
        if valid_physical_counts(groups, pair):
            return groups, pair
    raise RuntimeError("could not generate an open standard hand")


def full_concealed_kinds(groups: list[GroupSpec], pair: int) -> list[int]:
    kinds = [pair, pair]
    for group in groups:
        if group.meld_kind is None:
            kinds.extend(group.kinds())
    return kinds


def allocate_physical_tiles(
    concealed_kinds: list[int],
    groups: list[GroupSpec],
) -> tuple[list[int], list[tuple[GroupSpec, list[int]]]]:
    used = [0] * 34

    def take(kind: int) -> int:
        physical = kind * 4 + used[kind]
        used[kind] += 1
        return physical

    concealed = [take(kind) for kind in concealed_kinds]
    melds = []
    for group in groups:
        if group.meld_kind is not None:
            melds.append((group, [take(kind) for kind in group.kinds()]))
    return concealed, melds


def notation(kinds: list[int]) -> str:
    counts = Counter(kinds)
    parts = []
    for suit, suffix in ((0, "m"), (1, "p"), (2, "s")):
        digits = "".join(str(rank + 1) * counts[suit * 9 + rank] for rank in range(9))
        if digits:
            parts.append(digits + suffix)
    honors = "".join(str(rank + 1) * counts[27 + rank] for rank in range(7))
    if honors:
        parts.append(honors + "z")
    return "".join(parts)


def context_for(rng: random.Random, is_open: bool) -> ContextSpec:
    tsumo = rng.random() < 0.5
    riichi = 0 if is_open else (2 if rng.random() < 0.14 else 1)
    last_tile = rng.random() < 0.12
    return ContextSpec(
        tsumo=tsumo,
        seat=rng.randrange(4),
        round=rng.randrange(4),
        riichi=riichi,
        ippatsu=riichi > 0 and rng.random() < 0.18,
        haitei=tsumo and last_tile,
        houtei=not tsumo and last_tile,
        honba=rng.randrange(3),
        riichi_sticks=rng.randrange(3),
    )


def reference_options() -> OptionalRules:
    return OptionalRules(
        has_open_tanyao=True,
        has_aka_dora=False,
        has_double_yakuman=True,
        kazoe_limit=HandConfig.KAZOE_LIMITED,
        kiriage=False,
        fu_for_open_pinfu=True,
        fu_for_pinfu_tsumo=False,
        limit_to_sextuple_yakuman=False,
    )


def limit_and_base(han: int, fu: int, yakuman_multiplier: int) -> tuple[str, int]:
    if yakuman_multiplier > 0:
        return f"Yakuman({yakuman_multiplier})", 8000 * yakuman_multiplier
    if han >= 13:
        return "Yakuman(1)", 8000
    if han >= 11:
        return "Sanbaiman", 6000
    if han >= 8:
        return "Baiman", 4000
    if han >= 6:
        return "Haneman", 3000
    if han >= 5 or (han == 4 and fu >= 40) or (han == 3 and fu >= 70):
        return "Mangan", 2000
    return "BelowMangan", fu * (2 ** (han + 2))


def normalize_reference(result, context: ContextSpec) -> ExpectedSpec:
    if result.error:
        raise RuntimeError(f"reference rejected generated hand: {result.error}")
    bonuses = {"dora": 0, "ura_dora": 0, "aka_dora": 0}
    yaku_specs = []
    has_yakuman = any(yaku.is_yakuman for yaku in result.yaku or [])
    for yaku in result.yaku or []:
        class_name = type(yaku).__name__
        bonus_name = BONUS_CLASSES.get(class_name)
        if bonus_name is not None:
            bonuses[bonus_name] = yaku.han_open if result.is_open_hand else yaku.han_closed
            continue
        constructor = YAKU_CLASS_TO_CONSTRUCTOR.get(class_name)
        if constructor is None:
            raise RuntimeError(f"unsupported reference yaku: {class_name}")
        if yaku.is_yakuman:
            multiplier = max(yaku.han_closed, yaku.han_open) // 13
            yaku_specs.append(YakuSpec(constructor, 0, multiplier))
        else:
            value = yaku.han_open if result.is_open_hand else yaku.han_closed
            yaku_specs.append(YakuSpec(constructor, value, 0))
    yaku_specs.sort(key=lambda value: YAKU_ORDER[value.constructor])
    if has_yakuman:
        bonuses = {"dora": 0, "ura_dora": 0, "aka_dora": 0}
        han = 0
        fu = 0
    else:
        han = result.han
        fu = result.fu
    yakuman_multiplier = sum(value.yakuman_multiplier for value in yaku_specs)
    limit, base_points = limit_and_base(han, fu, yakuman_multiplier)
    cost = result.cost
    main = cost["main"] + cost["main_bonus"]
    additional = cost["additional"] + cost["additional_bonus"]
    if not context.tsumo:
        payment = f"RonPayment(discarder={main})"
    elif context.seat == 0:
        payment = f"DealerTsumoPayment(each={main})"
    else:
        payment = (
            "NonDealerTsumoPayment("
            f"dealer={main}, non_dealer_each={additional})"
        )
    return ExpectedSpec(
        yaku=tuple(yaku_specs),
        dora=bonuses["dora"],
        ura_dora=bonuses["ura_dora"],
        aka_dora=bonuses["aka_dora"],
        han=han,
        fu=fu,
        limit=limit,
        base_points=base_points,
        payment=payment,
        riichi_bonus=cost["kyoutaku_bonus"],
        winner_gain=cost["total"],
    )


def make_case(index: int, rng: random.Random) -> CaseSpec:
    family_slot = index % 50
    if family_slot < 35:
        family = "closed"
        groups, pair = closed_standard_shape(rng, with_kan=family_slot in (0, 1))
        concealed_full = full_concealed_kinds(groups, pair)
        winning_position = rng.randrange(len(concealed_full))
    elif family_slot < 45:
        family = "open"
        groups, pair = open_standard_shape(rng, with_kan=family_slot == 35)
        concealed_full = full_concealed_kinds(groups, pair)
        winning_position = rng.randrange(len(concealed_full))
    elif family_slot < 49:
        family = "seven_pairs"
        pairs = rng.sample(range(34), 7)
        groups = []
        concealed_full = [kind for kind in pairs for _ in range(2)]
        winning_position = rng.randrange(len(concealed_full))
    else:
        family = "kokushi"
        groups = []
        winning = rng.choice(ORPHANS)
        if rng.random() < 0.5:
            concealed_full = list(ORPHANS) + [winning]
            winning_position = len(concealed_full) - 1
        else:
            pair = rng.choice([kind for kind in ORPHANS if kind != winning])
            concealed_full = list(ORPHANS) + [pair]
            winning_position = concealed_full.index(winning)

    is_open = any(group.meld_kind not in (None, "closed_kan") for group in groups)
    context = context_for(rng, is_open)
    concealed_ids, allocated_melds = allocate_physical_tiles(concealed_full, groups)
    winning_id = concealed_ids[winning_position]
    concealed = concealed_full.copy()
    winning_kind = concealed.pop(winning_position)
    dora_indicators = tuple(rng.randrange(34) for _ in range(rng.randrange(3)))
    ura_dora_indicators = (
        tuple(rng.randrange(34) for _ in range(rng.randrange(3)))
        if context.riichi > 0
        else ()
    )
    reference_melds = []
    moon_melds = []
    all_tiles = concealed_ids.copy()
    for group, physical_tiles in allocated_melds:
        all_tiles.extend(physical_tiles)
        if group.meld_kind == "chi":
            meld_type, opened = Meld.CHI, True
        elif group.meld_kind == "pon":
            meld_type, opened = Meld.PON, True
        elif group.meld_kind == "closed_kan":
            meld_type, opened = Meld.KAN, False
        elif group.meld_kind == "added_kan":
            meld_type, opened = Meld.SHOUMINKAN, True
        else:
            meld_type, opened = Meld.KAN, True
        reference_melds.append(Meld(meld_type=meld_type, tiles=physical_tiles, opened=opened))
        moon_melds.append((MELD_KIND_NUMBER[group.meld_kind], tuple(group.kinds())))

    config = HandConfig(
        is_tsumo=context.tsumo,
        is_riichi=context.riichi > 0,
        is_daburu_riichi=context.riichi == 2,
        is_ippatsu=context.ippatsu,
        is_haitei=context.haitei,
        is_houtei=context.houtei,
        player_wind=27 + context.seat,
        round_wind=27 + context.round,
        kyoutaku_number=context.riichi_sticks,
        tsumi_number=context.honba,
        options=reference_options(),
    )
    result = HandCalculator.estimate_hand_value(
        all_tiles,
        winning_id,
        melds=reference_melds,
        dora_indicators=[kind * 4 + 3 for kind in dora_indicators],
        ura_dora_indicators=[kind * 4 + 3 for kind in ura_dora_indicators],
        config=config,
    )
    hand_name = notation(concealed_full + [kind for group in groups if group.meld_kind is not None for kind in group.kinds()])
    method = "tsumo" if context.tsumo else "ron"
    try:
        expected = normalize_reference(result, context)
    except RuntimeError as error:
        raise RuntimeError(f"case {index} {family} {hand_name} {method}: {error}") from error
    return CaseSpec(
        name=f"{index}:{family}:{hand_name}:{method}:win={winning_kind}",
        concealed=tuple(concealed),
        winning=winning_kind,
        melds=tuple(moon_melds),
        dora_indicators=dora_indicators,
        ura_dora_indicators=ura_dora_indicators,
        context=context,
        expected=expected,
    )


def moon_bool(value: bool) -> str:
    return "true" if value else "false"


def moon_array(values) -> str:
    return "[" + ", ".join(str(value) for value in values) + "]"


def render_yaku(values: tuple[YakuSpec, ...]) -> str:
    rendered = []
    for value in values:
        rendered.append(
            "{ yaku: "
            f"{value.constructor}, han: {value.han}, "
            f"yakuman_multiplier: {value.yakuman_multiplier} }}"
        )
    return "[" + ", ".join(rendered) + "]"


def render_case(case: CaseSpec) -> str:
    melds = "[" + ", ".join(
        f"{{ kind: {kind}, tiles: {moon_array(tiles)} }}" for kind, tiles in case.melds
    ) + "]"
    context = case.context
    expected = case.expected
    escaped_name = case.name.replace("\\", "\\\\").replace('"', '\\"')
    return f"""    {{
      name: \"{escaped_name}\",
      concealed: {moon_array(case.concealed)},
      winning: {case.winning},
      melds: {melds},
      dora_indicators: {moon_array(case.dora_indicators)},
      ura_dora_indicators: {moon_array(case.ura_dora_indicators)},
      tsumo: {moon_bool(context.tsumo)},
      seat: {context.seat},
      round: {context.round},
      riichi: {context.riichi},
      ippatsu: {moon_bool(context.ippatsu)},
      haitei: {moon_bool(context.haitei)},
      houtei: {moon_bool(context.houtei)},
      honba: {context.honba},
      riichi_sticks: {context.riichi_sticks},
      expected: {{
        yaku: {render_yaku(expected.yaku)},
        bonus_han: {{ dora: {expected.dora}, ura_dora: {expected.ura_dora}, aka_dora: {expected.aka_dora} }},
        han: {expected.han},
        fu: {expected.fu},
        limit: {expected.limit},
        base_points: {expected.base_points},
        payment: {expected.payment},
        riichi_bonus: {expected.riichi_bonus},
        winner_gain: {expected.winner_gain},
      }},
    }}"""


def render_test(cases: list[CaseSpec], seed: int) -> str:
    chunks = [cases[index : index + 250] for index in range(0, len(cases), 250)]
    case_functions = []
    for index, chunk in enumerate(chunks):
        rendered_cases = ",\n".join(render_case(case) for case in chunk)
        case_functions.append(
            f"""///|
fn cf_cases_{index}() -> Array[CfCase] {{
  [
{rendered_cases}
  ]
}}"""
        )
    rendered_functions = "\n\n".join(case_functions)
    chunk_calls = ", ".join(f"cf_cases_{index}()" for index in range(len(chunks)))
    return f"""// Generated by tools/conformance/check.py. Do not commit.

///|
struct CfMeldSpec {{
  kind : Int
  tiles : Array[Int]
}}

///|
struct CfExpected {{
  yaku : Array[@mahjong.YakuValue]
  bonus_han : @mahjong.BonusHan
  han : Int
  fu : Int
  limit : @mahjong.Limit
  base_points : Int
  payment : @mahjong.WinPayment
  riichi_bonus : Int
  winner_gain : Int
}} derive(Debug, Eq)

///|
struct CfCase {{
  name : String
  concealed : Array[Int]
  winning : Int
  melds : Array[CfMeldSpec]
  dora_indicators : Array[Int]
  ura_dora_indicators : Array[Int]
  tsumo : Bool
  seat : Int
  round : Int
  riichi : Int
  ippatsu : Bool
  haitei : Bool
  houtei : Bool
  honba : Int
  riichi_sticks : Int
  expected : CfExpected
}}

///|
fn cf_tile(kind : Int) -> @mahjong.Tile {{
  if kind < 9 {{
    try! @mahjong.Tile::numbered(Man, kind + 1)
  }} else if kind < 18 {{
    try! @mahjong.Tile::numbered(Pin, kind - 8)
  }} else if kind < 27 {{
    try! @mahjong.Tile::numbered(Sou, kind - 17)
  }} else {{
    @mahjong.Tile::honor(match kind {{
      27 => East
      28 => South
      29 => West
      30 => North
      31 => White
      32 => Green
      _ => Red
    }})
  }}
}}

///|
fn cf_tiles(kinds : Array[Int]) -> Array[@mahjong.Tile] {{
  kinds.map(cf_tile)
}}

///|
fn cf_wind(value : Int) -> @mahjong.Wind {{
  match value {{
    0 => East
    1 => South
    2 => West
    _ => North
  }}
}}

///|
fn cf_meld(spec : CfMeldSpec) -> @mahjong.Meld {{
  {{
    kind: match spec.kind {{
      0 => Chi
      1 => Pon
      2 => OpenKan
      3 => ClosedKan
      _ => AddedKan
    }},
    tiles: cf_tiles(spec.tiles),
  }}
}}

///|
fn cf_input(case : CfCase) -> @mahjong.HandInput {{
  {{
    concealed_tiles: cf_tiles(case.concealed),
    winning_tile: cf_tile(case.winning),
    melds: case.melds.map(cf_meld),
    dora_indicators: cf_tiles(case.dora_indicators),
    ura_dora_indicators: cf_tiles(case.ura_dora_indicators),
    context: {{
      win_method: if case.tsumo {{ Tsumo }} else {{ Ron }},
      seat_wind: cf_wind(case.seat),
      round_wind: cf_wind(case.round),
      riichi: match case.riichi {{
        0 => NoRiichi
        1 => Riichi
        _ => DoubleRiichi
      }},
      ippatsu: case.ippatsu,
      rinshan: false,
      chankan: false,
      haitei: case.haitei,
      houtei: case.houtei,
      tenhou: false,
      chiihou: false,
      honba: case.honba,
      riichi_sticks: case.riichi_sticks,
    }},
  }}
}}

///|
fn cf_summary(result : @mahjong.ScoreResult) -> CfExpected {{
  {{
    yaku: result.yaku,
    bonus_han: result.bonus_han,
    han: result.han,
    fu: result.fu,
    limit: result.limit,
    base_points: result.base_points,
    payment: result.payment,
    riichi_bonus: result.riichi_bonus,
    winner_gain: result.winner_gain,
  }}
}}

{rendered_functions}

///|
fn cf_case_chunks() -> Array[Array[CfCase]] {{
  [{chunk_calls}]
}}

///|
test \"MahjongRepository conformance seed={seed} cases={len(cases)}\" {{
  for cases in cf_case_chunks() {{
    for case in cases {{
      let actual = cf_summary(@mahjong.score_standard(cf_input(case)))
      assert_eq((case.name, actual), (case.name, case.expected))
    }}
  }}
}}
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cases", type=int, default=500)
    parser.add_argument("--seed", type=int, default=20260801)
    parser.add_argument("--target", choices=("native", "wasm", "wasm-gc"), default="native")
    parser.add_argument("--keep-generated", action="store_true")
    args = parser.parse_args()
    if args.cases < 1:
        parser.error("--cases must be at least 1")
    return args


def main() -> int:
    args = parse_args()
    rng = random.Random(args.seed)
    cases = [make_case(index, rng) for index in range(args.cases)]
    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        prefix="conformance_generated_",
        suffix="_test.mbt",
        dir=ROOT / "src",
        delete=False,
    ) as generated:
        generated.write(render_test(cases, args.seed))
        generated_path = Path(generated.name)
    relative_path = generated_path.relative_to(ROOT)
    print(
        f"reference={REFERENCE_COMMIT} seed={args.seed} "
        f"cases={args.cases} target={args.target}",
        flush=True,
    )
    result = subprocess.run(
        ["moon", "test", str(relative_path), "--target", args.target],
        cwd=ROOT,
        check=False,
    )
    if result.returncode == 0 and not args.keep_generated:
        generated_path.unlink()
    else:
        print(f"generated test retained at {relative_path}")
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
