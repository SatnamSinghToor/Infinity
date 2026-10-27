/// How well one word in a search asks for one word in a product: matches a
/// small typo ("meggi" for "Maggi") without matching two different words by
/// accident.
///
/// A search box that must match letter-for-letter turns a real typo into a
/// dead end. This gives typed words a little room — an edit or two — while
/// staying exact enough that unrelated words still miss.
library;

/// The edit distance between two words: the fewest single-letter changes
/// (insert, delete, substitute) that turn one into the other. Two identical
/// words are 0 apart; "cat" and "cot" are 1 apart.
int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  var current = List<int>.filled(b.length + 1, 0);
  for (var i = 0; i < a.length; i++) {
    current[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final cost = a[i] == b[j] ? 0 : 1;
      current[j + 1] = [
        current[j] + 1, // insert
        previous[j + 1] + 1, // delete
        previous[j] + cost, // substitute
      ].reduce((x, y) => x < y ? x : y);
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[b.length];
}

/// How many typos a word of this length may have and still count as a
/// match. Short words have almost no room, or "hi" would match half the
/// dictionary; longer words can carry a real typo or two.
int _typoBudget(int length) {
  if (length <= 3) return 0;
  if (length <= 6) return 1;
  return 2;
}

/// Whether [word] (as typed) is close enough to [target] (from a product)
/// to count as the same word: an exact match, a prefix ("mag" in "maggi"),
/// or within its typo budget.
bool wordMatches(String word, String target) {
  if (word.isEmpty || target.isEmpty) return false;
  if (target.contains(word)) return true;
  if (word.length < 4) return false; // too short to fuzzy-match safely
  final budget = _typoBudget(word.length);
  if (budget == 0) return false;
  // Compare against the target itself and each of its words, so "meggi
  // noodle" still finds "Maggi 2-Minute Noodles" by its first word.
  for (final piece in [target, ...target.split(RegExp(r'\s+'))]) {
    if (piece.length < word.length - budget) continue;
    if (levenshtein(word, piece) <= budget) return true;
  }
  return false;
}

/// How strongly one typed word matches one field of a product, from 0 (no
/// match) to 4 (the strongest). Used to rank results: a search should put
/// the product named after the word above one that merely shares its
/// brand or store.
int fieldScore(String word, String? field) {
  if (field == null || field.isEmpty) return 0;
  final f = field.toLowerCase();
  final w = word.toLowerCase();
  if (f == w) return 4;
  if (f.startsWith(w)) return 3;
  if (wordMatches(w, f)) return 2;
  return 0;
}

/// The words in [vocabulary] closest to [query], for "Did you mean…?" when
/// a search finds nothing. Only words within a small edit distance count,
/// so an unrelated query gets no suggestion rather than a wrong one.
List<String> nearestTerms(String query, Iterable<String> vocabulary,
    {int take = 3}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final budget = _typoBudget(q.length) + 1; // a little more room to suggest
  final scored = <MapEntry<String, int>>[];
  final seen = <String>{};
  for (final term in vocabulary) {
    final t = term.trim();
    if (t.isEmpty || !seen.add(t.toLowerCase())) continue;
    final dist = levenshtein(q, t.toLowerCase());
    if (dist <= budget) scored.add(MapEntry(t, dist));
  }
  scored.sort((a, b) => a.value.compareTo(b.value));
  return scored.take(take).map((e) => e.key).toList();
}
