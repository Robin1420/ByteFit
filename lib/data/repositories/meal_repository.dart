import '../../domain/entities/meal.dart';
import '../datasources/local_datasource.dart';

class MealRepository {
  final LocalDataSource _dataSource;

  MealRepository(this._dataSource);

  Future<void> saveMeal(Meal meal) async {
    await _dataSource.saveMeal(meal);
  }

  Future<List<Meal>> getMeals() async {
    return await _dataSource.getMeals();
  }

  Future<List<Meal>> getMealsByDate(DateTime date) async {
    return await _dataSource.getMealsByDate(date);
  }

  Future<void> updateMeal(int key, Meal meal) async {
    await _dataSource.updateMeal(key, meal);
  }

  Future<void> deleteMeal(int key) async {
    await _dataSource.deleteMeal(key);
  }

  // Obtener comidas de la última semana
  Future<List<Meal>> getMealsLastWeek() async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final allMeals = await getMeals();
    return allMeals.where((meal) => meal.fecha.isAfter(weekAgo)).toList();
  }

  // Obtener calorías totales de un día
  Future<double> getTotalCaloriesByDate(DateTime date) async {
    final meals = await getMealsByDate(date);
    return meals.fold<double>(0, (sum, meal) => sum + meal.calorias);
  }

  // Obtener todas las comidas
  Future<List<Meal>> getAllMeals() async {
    return await getMeals();
  }

  // Eliminar todas las comidas
  Future<void> deleteAllMeals() async {
    final meals = await getMeals();
    for (final meal in meals) {
      await deleteMeal(meal.id);
    }
  }
}
