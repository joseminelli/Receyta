import 'package:shared_preferences/shared_preferences.dart';

/// Marcos que o mascote comemora uma única vez na vida do app.
enum Milestone {
  firstRecipe('milestone_first_recipe'),
  firstWeekPlanned('milestone_first_week_planned'),
  tenthCooked('milestone_tenth_cooked');

  const Milestone(this.key);

  final String key;
}

/// Tenta "ganhar" o [milestone]: devolve `true` só na primeira vez (e grava
/// que já foi comemorado), `false` nas seguintes ou se o armazenamento falhar
/// — nunca comemora duas vezes nem trava o fluxo de quem chama.
Future<bool> claimMilestone(Milestone milestone) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(milestone.key) ?? false) return false;
    await prefs.setBool(milestone.key, true);
    return true;
  } catch (_) {
    return false;
  }
}
