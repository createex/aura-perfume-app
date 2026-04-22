/// Catalog ratings are stored on a **0–10** scale everywhere in the app.
class RatingFormat {
  RatingFormat._();

  /// List / pill: single value (e.g. `7.5`).
  static String pill(double rating10) =>
      rating10.clamp(0, 10).toStringAsFixed(1);

  /// Grid tile: explicit scale (e.g. `7.5 / 10`).
  static String gridFraction(double rating10) =>
      '${pill(rating10)} / 10';
}
