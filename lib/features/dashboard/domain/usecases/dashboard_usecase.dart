import 'package:wellness_app/features/categories/data/models/category_model.dart';
import 'package:wellness_app/features/tips/data/models/tips_model.dart';

class DashboardUseCase {
  List<CategoryModel> filterCategories(
    List<CategoryModel> categories,
    Set<String> userPreferenceIds,
  ) {
    return categories
        .where(
          (category) => category.preferenceIds.any(
            (id) => userPreferenceIds.contains(id),
          ),
        )
        .toList();
  }

  List<TipModel> filterFeaturedQuotes(
    List<TipModel> tips,
    Set<String> userPreferenceIds,
  ) {
    return tips
        .where(
          (tip) =>
              tip.isFeatured &&
              tip.tipsType == 'quote' &&
              tip.preferenceIds.any((id) => userPreferenceIds.contains(id)),
        )
        .take(4)
        .toList();
  }

  Map<String, List<TipModel>> groupTipsByCategory(
    List<TipModel> tips,
    List<CategoryModel> categories,
    Set<String> userPreferenceIds,
  ) {
    final categoryTips = <String, List<TipModel>>{};
    for (var category in categories) {
      final tipsForCategory = tips
          .where(
            (tip) =>
                tip.categoryId == category.categoryId &&
                tip.preferenceIds.any((id) => userPreferenceIds.contains(id)),
          )
          .toList();
      if (tipsForCategory.isNotEmpty) {
        categoryTips[category.categoryId] = tipsForCategory;
      }
    }
    return categoryTips;
  }
}
