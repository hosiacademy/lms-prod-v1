// lib/src/presentation/blocs/student_portal/wishlist_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/wishlist.dart';
import '../../../core/api/student_portal_api_service.dart';

// ===================================
// EVENTS
// ===================================

abstract class WishlistEvent extends Equatable {
  const WishlistEvent();

  @override
  List<Object?> get props => [];
}

class LoadWishlist extends WishlistEvent {}

class LoadWishlistByType extends WishlistEvent {
  final String trainingType;

  const LoadWishlistByType(this.trainingType);

  @override
  List<Object?> get props => [trainingType];
}

class AddToWishlistEvent extends WishlistEvent {
  final int contentTypeId;
  final int objectId;
  final String trainingType;
  final String interestLevel;
  final String intendedStart;
  final String? notes;

  const AddToWishlistEvent({
    required this.contentTypeId,
    required this.objectId,
    required this.trainingType,
    required this.interestLevel,
    required this.intendedStart,
    this.notes,
  });

  @override
  List<Object?> get props => [contentTypeId, objectId, trainingType, interestLevel, intendedStart, notes];
}

class RemoveFromWishlistEvent extends WishlistEvent {
  final int wishlistId;

  const RemoveFromWishlistEvent(this.wishlistId);

  @override
  List<Object?> get props => [wishlistId];
}

class MoveToCartEvent extends WishlistEvent {
  final int wishlistId;

  const MoveToCartEvent(this.wishlistId);

  @override
  List<Object?> get props => [wishlistId];
}

// ===================================
// STATES
// ===================================

abstract class WishlistState extends Equatable {
  const WishlistState();

  @override
  List<Object?> get props => [];
}

class WishlistInitial extends WishlistState {}

class WishlistLoading extends WishlistState {}

class WishlistLoaded extends WishlistState {
  final List<Wishlist> items;
  final String? filterType;

  const WishlistLoaded(this.items, {this.filterType});

  @override
  List<Object?> get props => [items, filterType];

  List<Wishlist> get unconvertedItems => items.where((item) =>
    !item.convertedToCart && !item.convertedToEnrollment
  ).toList();

  List<Wishlist> get highPriorityItems => items.where((item) =>
    item.interestLevel == 'high' && !item.convertedToCart && !item.convertedToEnrollment
  ).toList();

  Map<String, List<Wishlist>> get itemsByType {
    final map = <String, List<Wishlist>>{};
    for (final item in items) {
      if (!map.containsKey(item.trainingType)) {
        map[item.trainingType] = [];
      }
      map[item.trainingType]!.add(item);
    }
    return map;
  }
}

class WishlistError extends WishlistState {
  final String message;

  const WishlistError(this.message);

  @override
  List<Object?> get props => [message];
}

class WishlistItemAdded extends WishlistState {
  final Wishlist item;

  const WishlistItemAdded(this.item);

  @override
  List<Object?> get props => [item];
}

class WishlistItemRemoved extends WishlistState {
  final int wishlistId;

  const WishlistItemRemoved(this.wishlistId);

  @override
  List<Object?> get props => [wishlistId];
}

class WishlistItemMovedToCart extends WishlistState {
  final int wishlistId;
  final int cartId;

  const WishlistItemMovedToCart(this.wishlistId, this.cartId);

  @override
  List<Object?> get props => [wishlistId, cartId];
}

// ===================================
// BLOC
// ===================================

class WishlistBloc extends Bloc<WishlistEvent, WishlistState> {
  WishlistBloc() : super(WishlistInitial()) {
    on<LoadWishlist>(_onLoadWishlist);
    on<LoadWishlistByType>(_onLoadWishlistByType);
    on<AddToWishlistEvent>(_onAddToWishlist);
    on<RemoveFromWishlistEvent>(_onRemoveFromWishlist);
    on<MoveToCartEvent>(_onMoveToCart);
  }

  Future<void> _onLoadWishlist(
    LoadWishlist event,
    Emitter<WishlistState> emit,
  ) async {
    emit(WishlistLoading());
    try {
      final items = await LearnerPortalApiService.getWishlist();
      emit(WishlistLoaded(items));
    } catch (e) {
      emit(WishlistError('Failed to load wishlist: ${e.toString()}'));
    }
  }

  Future<void> _onLoadWishlistByType(
    LoadWishlistByType event,
    Emitter<WishlistState> emit,
  ) async {
    emit(WishlistLoading());
    try {
      final items = await LearnerPortalApiService.getWishlistByTrainingType(event.trainingType);
      emit(WishlistLoaded(items, filterType: event.trainingType));
    } catch (e) {
      emit(WishlistError('Failed to load wishlist: ${e.toString()}'));
    }
  }

  Future<void> _onAddToWishlist(
    AddToWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    try {
      final item = await LearnerPortalApiService.addToWishlist(
        contentTypeId: event.contentTypeId,
        objectId: event.objectId,
        trainingType: event.trainingType,
        interestLevel: event.interestLevel,
        intendedStart: event.intendedStart,
        notes: event.notes,
      );
      emit(WishlistItemAdded(item));
      // Reload wishlist
      add(LoadWishlist());
    } catch (e) {
      emit(WishlistError('Failed to add to wishlist: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveFromWishlist(
    RemoveFromWishlistEvent event,
    Emitter<WishlistState> emit,
  ) async {
    try {
      await LearnerPortalApiService.removeFromWishlist(event.wishlistId);
      emit(WishlistItemRemoved(event.wishlistId));
      // Reload wishlist
      add(LoadWishlist());
    } catch (e) {
      emit(WishlistError('Failed to remove from wishlist: ${e.toString()}'));
    }
  }

  Future<void> _onMoveToCart(
    MoveToCartEvent event,
    Emitter<WishlistState> emit,
  ) async {
    try {
      final result = await LearnerPortalApiService.moveWishlistToCart(event.wishlistId);
      final cartId = result['cart_id'] as int;
      emit(WishlistItemMovedToCart(event.wishlistId, cartId));
      // Reload wishlist
      add(LoadWishlist());
    } catch (e) {
      emit(WishlistError('Failed to move to cart: ${e.toString()}'));
    }
  }
}
