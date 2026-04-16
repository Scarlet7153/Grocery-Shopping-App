import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/products/data/unit_model.dart';
import '../../../features/products/data/unit_service.dart';

// Events
abstract class UnitEvent {}

class LoadUnits extends UnitEvent {}

class LoadUnitCategories extends UnitEvent {}

class LoadUnitsByCategory extends UnitEvent {
  final int categoryId;
  LoadUnitsByCategory(this.categoryId);
}

// States
abstract class UnitState {}

class UnitInitial extends UnitState {}

class UnitLoading extends UnitState {}

class UnitsLoaded extends UnitState {
  final List<Unit> units;
  UnitsLoaded(this.units);
}

class UnitCategoriesLoaded extends UnitState {
  final List<UnitCategory> categories;
  UnitCategoriesLoaded(this.categories);
}

class UnitsByCategoryLoaded extends UnitState {
  final Map<UnitCategory, List<Unit>> organizedUnits;
  UnitsByCategoryLoaded(this.organizedUnits);
}

class UnitError extends UnitState {
  final String message;
  UnitError(this.message);
}

// BLoC
class UnitBloc extends Bloc<UnitEvent, UnitState> {
  final UnitService _unitService;

  UnitBloc({UnitService? unitService})
      : _unitService = unitService ?? UnitService(),
        super(UnitInitial()) {
    on<LoadUnits>(_onLoadUnits);
    on<LoadUnitCategories>(_onLoadUnitCategories);
    on<LoadUnitsByCategory>(_onLoadUnitsByCategory);
  }

  Future<void> _onLoadUnits(LoadUnits event, Emitter<UnitState> emit) async {
    emit(UnitLoading());
    try {
      final units = await _unitService.getAllUnits();
      emit(UnitsLoaded(units));
    } catch (e) {
      emit(UnitError('Failed to load units: $e'));
    }
  }

  Future<void> _onLoadUnitCategories(
      LoadUnitCategories event, Emitter<UnitState> emit) async {
    emit(UnitLoading());
    try {
      final categories = await _unitService.getUnitCategories();
      emit(UnitCategoriesLoaded(categories));
    } catch (e) {
      emit(UnitError('Failed to load categories: $e'));
    }
  }

  Future<void> _onLoadUnitsByCategory(
      LoadUnitsByCategory event, Emitter<UnitState> emit) async {
    emit(UnitLoading());
    try {
      final organized = await _unitService.getUnitsOrganizedByCategory();
      emit(UnitsByCategoryLoaded(organized));
    } catch (e) {
      emit(UnitError('Failed to load units: $e'));
    }
  }
}
