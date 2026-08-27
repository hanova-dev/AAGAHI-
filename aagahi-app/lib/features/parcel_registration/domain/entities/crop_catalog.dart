/// The five crop categories B3 offers (screens_v2.html flow B).
///
/// [fodder] has no picture grid behind it - the reference only supplies
/// content for four of the five categories (flow-note: "a category chooser
/// plus four picture grids"). Its tile is still shown, honestly disabled,
/// rather than routing to a grid of fabricated crop names (CLAUDE.md S1).
enum CropCategory { cereals, pulsesOilseeds, vegetables, fruits, fodder }

/// One selectable crop (screens_v2.html B3a-B3d). [nameKey]/[nameKeyUrdu]
/// resolve through `AppLocalisations.translate` like every other
/// user-visible string in the app; the Urdu here is the reference's own
/// verbatim per-crop label, not invented for this catalog.
final class CropOption {
  const CropOption({
    required this.id,
    required this.category,
    required this.icon,
    required this.nameKey,
  });

  final String id;
  final CropCategory category;
  final String icon;
  final String nameKey;
}

/// The 47 named crops across the four built categories (screens_v2.html
/// B3a-B3d, transcribed in the order shown there) - not a general-purpose
/// agronomy database, just what the reference actually enumerates. Fodder
/// has no entries here; see [CropCategory.fodder].
const cropCatalog = <CropOption>[
  // B3a - cereals & field crops
  CropOption(
      id: 'wheat',
      category: CropCategory.cereals,
      icon: '🌾',
      nameKey: 'crop.wheat'),
  CropOption(
      id: 'rice',
      category: CropCategory.cereals,
      icon: '🍚',
      nameKey: 'crop.rice'),
  CropOption(
      id: 'maize',
      category: CropCategory.cereals,
      icon: '🌽',
      nameKey: 'crop.maize'),
  CropOption(
      id: 'cotton',
      category: CropCategory.cereals,
      icon: '🧵',
      nameKey: 'crop.cotton'),
  CropOption(
      id: 'sugarcane',
      category: CropCategory.cereals,
      icon: '🎋',
      nameKey: 'crop.sugarcane'),
  CropOption(
      id: 'barley',
      category: CropCategory.cereals,
      icon: '🌾',
      nameKey: 'crop.barley'),
  CropOption(
      id: 'sorghum',
      category: CropCategory.cereals,
      icon: '🌾',
      nameKey: 'crop.sorghum'),
  CropOption(
      id: 'millet',
      category: CropCategory.cereals,
      icon: '🌾',
      nameKey: 'crop.millet'),
  CropOption(
      id: 'oats',
      category: CropCategory.cereals,
      icon: '🌾',
      nameKey: 'crop.oats'),
  CropOption(
      id: 'sugarBeet',
      category: CropCategory.cereals,
      icon: '🍠',
      nameKey: 'crop.sugarBeet'),
  CropOption(
      id: 'tobacco',
      category: CropCategory.cereals,
      icon: '🍂',
      nameKey: 'crop.tobacco'),
  CropOption(
      id: 'cerealsOther',
      category: CropCategory.cereals,
      icon: '➕',
      nameKey: 'crop.other'),

  // B3b - pulses & oilseeds
  CropOption(
      id: 'chickpea',
      category: CropCategory.pulsesOilseeds,
      icon: '🫘',
      nameKey: 'crop.chickpea'),
  CropOption(
      id: 'lentil',
      category: CropCategory.pulsesOilseeds,
      icon: '🫘',
      nameKey: 'crop.lentil'),
  CropOption(
      id: 'mung',
      category: CropCategory.pulsesOilseeds,
      icon: '🫛',
      nameKey: 'crop.mung'),
  CropOption(
      id: 'mash',
      category: CropCategory.pulsesOilseeds,
      icon: '🫘',
      nameKey: 'crop.mash'),
  CropOption(
      id: 'cowpea',
      category: CropCategory.pulsesOilseeds,
      icon: '🫛',
      nameKey: 'crop.cowpea'),
  CropOption(
      id: 'mustard',
      category: CropCategory.pulsesOilseeds,
      icon: '🌻',
      nameKey: 'crop.mustard'),
  CropOption(
      id: 'sunflower',
      category: CropCategory.pulsesOilseeds,
      icon: '🌻',
      nameKey: 'crop.sunflower'),
  CropOption(
      id: 'canola',
      category: CropCategory.pulsesOilseeds,
      icon: '🌼',
      nameKey: 'crop.canola'),
  CropOption(
      id: 'groundnut',
      category: CropCategory.pulsesOilseeds,
      icon: '🥜',
      nameKey: 'crop.groundnut'),
  CropOption(
      id: 'sesame',
      category: CropCategory.pulsesOilseeds,
      icon: '🌰',
      nameKey: 'crop.sesame'),
  CropOption(
      id: 'soybean',
      category: CropCategory.pulsesOilseeds,
      icon: '🫘',
      nameKey: 'crop.soybean'),
  CropOption(
      id: 'pulsesOilseedsOther',
      category: CropCategory.pulsesOilseeds,
      icon: '➕',
      nameKey: 'crop.other'),

  // B3c - vegetables
  CropOption(
      id: 'potato',
      category: CropCategory.vegetables,
      icon: '🥔',
      nameKey: 'crop.potato'),
  CropOption(
      id: 'onion',
      category: CropCategory.vegetables,
      icon: '🧅',
      nameKey: 'crop.onion'),
  CropOption(
      id: 'tomato',
      category: CropCategory.vegetables,
      icon: '🍅',
      nameKey: 'crop.tomato'),
  CropOption(
      id: 'chilli',
      category: CropCategory.vegetables,
      icon: '🌶️',
      nameKey: 'crop.chilli'),
  CropOption(
      id: 'garlic',
      category: CropCategory.vegetables,
      icon: '🧄',
      nameKey: 'crop.garlic'),
  CropOption(
      id: 'brinjal',
      category: CropCategory.vegetables,
      icon: '🍆',
      nameKey: 'crop.brinjal'),
  CropOption(
      id: 'okra',
      category: CropCategory.vegetables,
      icon: '🥬',
      nameKey: 'crop.okra'),
  CropOption(
      id: 'spinach',
      category: CropCategory.vegetables,
      icon: '🥬',
      nameKey: 'crop.spinach'),
  CropOption(
      id: 'cauliflower',
      category: CropCategory.vegetables,
      icon: '🥦',
      nameKey: 'crop.cauliflower'),
  CropOption(
      id: 'cabbage',
      category: CropCategory.vegetables,
      icon: '🥬',
      nameKey: 'crop.cabbage'),
  CropOption(
      id: 'carrot',
      category: CropCategory.vegetables,
      icon: '🥕',
      nameKey: 'crop.carrot'),
  CropOption(
      id: 'cucumber',
      category: CropCategory.vegetables,
      icon: '🥒',
      nameKey: 'crop.cucumber'),
  CropOption(
      id: 'pumpkin',
      category: CropCategory.vegetables,
      icon: '🎃',
      nameKey: 'crop.pumpkin'),
  CropOption(
      id: 'turnip',
      category: CropCategory.vegetables,
      icon: '🥬',
      nameKey: 'crop.turnip'),
  CropOption(
      id: 'vegetablesOther',
      category: CropCategory.vegetables,
      icon: '➕',
      nameKey: 'crop.other'),

  // B3d - fruits & orchards (no "Other" tile - the reference has none here)
  CropOption(
      id: 'mango',
      category: CropCategory.fruits,
      icon: '🥭',
      nameKey: 'crop.mango'),
  CropOption(
      id: 'kinnow',
      category: CropCategory.fruits,
      icon: '🍊',
      nameKey: 'crop.kinnow'),
  CropOption(
      id: 'guava',
      category: CropCategory.fruits,
      icon: '🍐',
      nameKey: 'crop.guava'),
  CropOption(
      id: 'dates',
      category: CropCategory.fruits,
      icon: '🌴',
      nameKey: 'crop.dates'),
  CropOption(
      id: 'banana',
      category: CropCategory.fruits,
      icon: '🍌',
      nameKey: 'crop.banana'),
  CropOption(
      id: 'apple',
      category: CropCategory.fruits,
      icon: '🍎',
      nameKey: 'crop.apple'),
  CropOption(
      id: 'grapes',
      category: CropCategory.fruits,
      icon: '🍇',
      nameKey: 'crop.grapes'),
  CropOption(
      id: 'peach',
      category: CropCategory.fruits,
      icon: '🍑',
      nameKey: 'crop.peach'),
  CropOption(
      id: 'pomegranate',
      category: CropCategory.fruits,
      icon: '🌸',
      nameKey: 'crop.pomegranate'),
  CropOption(
      id: 'watermelon',
      category: CropCategory.fruits,
      icon: '🍉',
      nameKey: 'crop.watermelon'),
  CropOption(
      id: 'melon',
      category: CropCategory.fruits,
      icon: '🍈',
      nameKey: 'crop.melon'),
  CropOption(
      id: 'olive',
      category: CropCategory.fruits,
      icon: '🫒',
      nameKey: 'crop.olive'),
];

CropOption cropById(String id) => cropCatalog.firstWhere((c) => c.id == id);
