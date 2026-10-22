/// Cor de acento de uma conquista; a tela traduz pra paleta do app.
enum AchievementTone { lime, coral, violet }

enum AchievementId {
  firstRecipe,
  library,
  favorites,
  firstCooked,
  chef,
  firstMeal,
  plannedWeek,
  firstShoppingList,
  house,
}

/// O aro da medalha: [none] enquanto bloqueada; bronze, prata e ouro nas
/// conquistas com níveis; [single] nas de um passo só (aro na cor da
/// categoria).
enum MedalTier { none, bronze, silver, gold, single }

/// Contagens do app que alimentam as conquistas.
class AchievementStats {
  const AchievementStats({
    this.recipes = 0,
    this.favorites = 0,
    this.cooked = 0,
    this.plannedMeals = 0,
    this.shoppingLists = 0,
    this.hasHouse = false,
    this.weekPlanned = false,
  });

  final int recipes;
  final int favorites;
  final int cooked;
  final int plannedMeals;
  final int shoppingLists;
  final bool hasHouse;

  /// Já usou o "Sugerir semana" pra planejar uma semana inteira.
  final bool weekPlanned;
}

/// Uma conquista com um ou mais níveis. [tiers] são as metas (crescentes) e
/// [titles]/[descriptions] dizem o nome e o que pede cada nível; [current] é a
/// contagem de agora.
class Achievement {
  const Achievement({
    required this.id,
    required this.tone,
    required this.tiers,
    required this.titles,
    required this.descriptions,
    required this.current,
  });

  final AchievementId id;
  final AchievementTone tone;
  final List<int> tiers;
  final List<String> titles;
  final List<String> descriptions;
  final int current;

  /// Quantos níveis já foram alcançados (0 = bloqueada).
  int get level => tiers.where((t) => current >= t).length;

  bool get unlocked => level >= 1;

  /// Todos os níveis conquistados.
  bool get maxed => level == tiers.length;

  bool get hasTiers => tiers.length > 1;

  /// Meta do próximo nível; nula quando já está no máximo.
  int? get nextTarget => maxed ? null : tiers[level];

  /// Nome e descrição do nível atual (ou do primeiro, se ainda bloqueada).
  String get title => titles[unlocked ? level - 1 : 0];
  String get description => descriptions[unlocked ? level - 1 : 0];

  /// Nome e descrição do próximo nível; nulos no máximo.
  String? get nextTitle => maxed ? null : titles[level];
  String? get nextDescription => maxed ? null : descriptions[level];

  /// Contagem a mostrar: a de agora, ou a última meta quando já está no
  /// máximo.
  int get shownCurrent => maxed ? tiers.last : current;

  /// Quanto falta andar (0 a 1) entre o nível atual e o próximo.
  double get progress {
    final target = nextTarget;
    if (target == null) return 1;
    final base = level == 0 ? 0 : tiers[level - 1];
    return ((current - base) / (target - base)).clamp(0.0, 1.0);
  }

  MedalTier get medal {
    if (!unlocked) return MedalTier.none;
    if (!hasTiers) return MedalTier.single;
    return switch (level) {
      1 => MedalTier.bronze,
      2 => MedalTier.silver,
      _ => MedalTier.gold,
    };
  }
}

/// As conquistas do app, na ordem em que aparecem na tela: cada uma deriva
/// das contagens reais, então nunca fica fora de sincronia com os dados.
List<Achievement> buildAchievements(AchievementStats s) {
  Achievement single(
    AchievementId id,
    AchievementTone tone,
    String title,
    String description,
    bool done,
  ) =>
      Achievement(
        id: id,
        tone: tone,
        tiers: const [1],
        titles: [title],
        descriptions: [description],
        current: done ? 1 : 0,
      );

  return [
    Achievement(
      id: AchievementId.firstRecipe,
      tone: AchievementTone.coral,
      tiers: const [1],
      titles: const ['Primeira receita'],
      descriptions: const ['Guarde a sua primeira receita.'],
      current: s.recipes,
    ),
    Achievement(
      id: AchievementId.library,
      tone: AchievementTone.coral,
      tiers: const [10, 25, 50],
      titles: const [
        'Caderno cheio',
        'Biblioteca de verdade',
        'Acervo de mestre'
      ],
      descriptions: const [
        'Tenha 10 receitas guardadas.',
        'Chegue a 25 receitas.',
        'Alcance 50 receitas.',
      ],
      current: s.recipes,
    ),
    Achievement(
      id: AchievementId.favorites,
      tone: AchievementTone.violet,
      tiers: const [1, 5, 10],
      titles: const ['Favorita', 'Coração de cozinha', 'Só as melhores'],
      descriptions: const [
        'Marque uma receita como favorita.',
        'Tenha 5 receitas favoritas.',
        'Tenha 10 receitas favoritas.',
      ],
      current: s.favorites,
    ),
    Achievement(
      id: AchievementId.firstCooked,
      tone: AchievementTone.lime,
      tiers: const [1],
      titles: const ['Mão na massa'],
      descriptions: const ['Registre a primeira receita que você cozinhou.'],
      current: s.cooked,
    ),
    Achievement(
      id: AchievementId.chef,
      tone: AchievementTone.lime,
      tiers: const [10, 25, 50],
      titles: const ['Cozinheiro de casa', 'Chef da família', 'Mestre-cuca'],
      descriptions: const [
        'Cozinhe 10 vezes.',
        'Cozinhe 25 vezes.',
        'Cozinhe 50 vezes.',
      ],
      current: s.cooked,
    ),
    Achievement(
      id: AchievementId.firstMeal,
      tone: AchievementTone.violet,
      tiers: const [1],
      titles: const ['Primeira refeição na agenda'],
      descriptions: const ['Agende uma refeição.'],
      current: s.plannedMeals,
    ),
    single(
      AchievementId.plannedWeek,
      AchievementTone.violet,
      'Semana planejada',
      'Monte uma semana com o "Sugerir semana".',
      s.weekPlanned,
    ),
    Achievement(
      id: AchievementId.firstShoppingList,
      tone: AchievementTone.lime,
      tiers: const [1],
      titles: const ['Lista de compras'],
      descriptions: const ['Crie a sua primeira lista de compras.'],
      current: s.shoppingLists,
    ),
    single(
      AchievementId.house,
      AchievementTone.coral,
      'Casa montada',
      'Crie ou entre numa casa pra dividir as listas.',
      s.hasHouse,
    ),
  ];
}
