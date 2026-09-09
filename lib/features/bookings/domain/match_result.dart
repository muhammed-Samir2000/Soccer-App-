class MatchResult {
  const MatchResult({
    required this.winningTeam,
    required this.manOfTheMatch,
    this.manOfTheMatchDescription = '',
    this.bestGoal = '',
    this.bestGoalDescription = '',
  });

  final String winningTeam;
  final String manOfTheMatch;
  final String manOfTheMatchDescription;
  final String bestGoal;
  final String bestGoalDescription;
}
