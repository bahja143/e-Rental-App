/// First display character for default avatars (home header, map explorer pin).
/// Empty string means “no initial” — show generic person, not a letter.
String profileAvatarLetterFromName(String name) {
  final t = name.trim();
  if (t.isEmpty) return '';
  final it = t.runes.iterator;
  if (it.moveNext()) {
    return String.fromCharCode(it.current).toUpperCase();
  }
  return '';
}
