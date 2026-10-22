/// Cor de acento de uma conquista; a tela traduz pra paleta do app.
enum AchievementTone { lime, coral, violet }

enum AchievementId {
  firstRecipe,
  tenRecipes,
  twentyFiveRecipes,
  firstFavorite,
  firstCooked,
  tenCooked,
  fiftyCooked,
  firstMeal,
  plannedWeek,
  firstShoppingList,
  house,
}

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

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.tone,
    required this.current,
    required this.target,
  });

  final AchievementId id;
  final String title;
  final String description;
  final AchievementTone tone;

  /// Progresso já limitado ao [target].
  final int current;
  final int target;

  bool get unlocked => current >= target;

  double get progress => target == 0 ? 1 : current / target;
}

/// As conquistas do app, na ordem em que aparecem na tela: cada uma deriva
/// das contagens reais, então nunca fica fora de sincronia com os dados.
List<Achievement> buildAchievements(AchievementStats s) {
  Achievement count(
    AchievementId id,
    String title,
    String description,
    AchievementTone tone,
    int current,
    int target,
  ) =>
      Achievement(
        id: id,
        title: title,
        description: description,
        tone: tone,
        current: current > target ? target : current,
        target: target,
      );

  Achievement flag(
    AchievementId id,
    String title,
    String description,
    AchievementTone tone,
    bool done,
  ) =>
      count(id, title, description, tone, done ? 1 : 0, 1);

  return [
    count(
      AchievementId.firstRecipe,
      'Primeira receita',
      'Guarde a sua primeira receita.',
      AchievementTone.coral,
      s.recipes,
      1,
    ),
    count(
      AchievementId.tenRecipes,
      'Caderno cheio',
      'Tenha 10 receitas guardadas.',
      AchievementTone.coral,
      s.recipes,
      10,
    ),
    count(
      AchievementId.twentyFiveRecipes,
      'Biblioteca de verdade',
      'Chegue a 25 receitas.',
      AchievementTone.coral,
      s.recipes,
      25,
    ),
    count(
      AchievementId.firstFavorite,
      'Favorita',
      'Marque uma receita como favorita.',
      AchievementTone.violet,
      s.favorites,
      1,
    ),
    count(
      AchievementId.firstCooked,
      'Mão na massa',
      'Registre a primeira receita que você cozinhou.',
      AchievementTone.lime,
      s.cooked,
      1,
    ),
    count(
      AchievementId.tenCooked,
      'Cozinheiro de casa',
      'Cozinhe 10 vezes.',
      AchievementTone.lime,
      s.cooked,
      10,
    ),
    count(
      AchievementId.fiftyCooked,
      'Chef da família',
      'Cozinhe 50 vezes.',
      AchievementTone.lime,
      s.cooked,
      50,
    ),
    count(
      AchievementId.firstMeal,
      'Primeira refeição na agenda',
      'Agende uma refeição.',
      AchievementTone.violet,
      s.plannedMeals,
      1,
    ),
    flag(
      AchievementId.plannedWeek,
      'Semana planejada',
      'Monte uma semana com o "Sugerir semana".',
      AchievementTone.violet,
      s.weekPlanned,
    ),
    count(
      AchievementId.firstShoppingList,
      'Lista de compras',
      'Crie a sua primeira lista de compras.',
      AchievementTone.lime,
      s.shoppingLists,
      1,
    ),
    flag(
      AchievementId.house,
      'Casa montada',
      'Crie ou entre numa casa pra dividir as listas.',
      AchievementTone.coral,
      s.hasHouse,
    ),
  ];
}
