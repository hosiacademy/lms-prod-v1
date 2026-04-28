// lib/src/presentation/blocs/student_portal/cart_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/course_cart.dart';
import '../../../core/api/student_portal_api_service.dart';

// ===================================
// EVENTS
// ===================================

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadActiveCart extends CartEvent {}

class AddToCartEvent extends CartEvent {
  final int contentTypeId;
  final int objectId;
  final String trainingType;
  final bool fromWishlist;

  const AddToCartEvent({
    required this.contentTypeId,
    required this.objectId,
    required this.trainingType,
    this.fromWishlist = false,
  });

  @override
  List<Object?> get props => [contentTypeId, objectId, trainingType, fromWishlist];
}

class RemoveFromCartEvent extends CartEvent {
  final int itemId;

  const RemoveFromCartEvent(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class ClearCartEvent extends CartEvent {}

class CheckoutCartEvent extends CartEvent {
  final bool usePreviousCompanyDetails;
  final bool isCorporateEnrollment;

  const CheckoutCartEvent({
    required this.usePreviousCompanyDetails,
    required this.isCorporateEnrollment,
  });

  @override
  List<Object?> get props => [usePreviousCompanyDetails, isCorporateEnrollment];
}

// ===================================
// STATES
// ===================================

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final CourseCart cart;

  const CartLoaded(this.cart);

  @override
  List<Object?> get props => [cart];

  bool get isEmpty => cart.isEmpty;
  bool get hasPreviousCompanyDetails => cart.hasPreviousCompanyDetails;
  int get itemCount => cart.totalCourses;
  String get totalAmount => cart.totalAmount;
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

class CartItemAdded extends CartState {
  final CourseCartItem item;

  const CartItemAdded(this.item);

  @override
  List<Object?> get props => [item];
}

class CartItemRemoved extends CartState {
  final int itemId;

  const CartItemRemoved(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class CartCleared extends CartState {}

class CartCheckoutReady extends CartState {
  final int cartId;
  final String orderId;
  final String totalAmount;
  final int totalCourses;
  final String currency;

  const CartCheckoutReady({
    required this.cartId,
    required this.orderId,
    required this.totalAmount,
    required this.totalCourses,
    required this.currency,
  });

  @override
  List<Object?> get props => [cartId, orderId, totalAmount, totalCourses, currency];
}

// ===================================
// BLOC
// ===================================

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartInitial()) {
    on<LoadActiveCart>(_onLoadActiveCart);
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<ClearCartEvent>(_onClearCart);
    on<CheckoutCartEvent>(_onCheckoutCart);
  }

  Future<void> _onLoadActiveCart(
    LoadActiveCart event,
    Emitter<CartState> emit,
  ) async {
    emit(CartLoading());
    try {
      final cart = await LearnerPortalApiService.getActiveCart();
      emit(CartLoaded(cart));
    } catch (e) {
      emit(CartError('Failed to load cart: ${e.toString()}'));
    }
  }

  Future<void> _onAddToCart(
    AddToCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      // Get or load current cart
      CourseCart? currentCart;
      if (state is CartLoaded) {
        currentCart = (state as CartLoaded).cart;
      } else {
        currentCart = await LearnerPortalApiService.getActiveCart();
      }

      final item = await LearnerPortalApiService.addToCart(
        cartId: currentCart.id,
        contentTypeId: event.contentTypeId,
        objectId: event.objectId,
        trainingType: event.trainingType,
        fromWishlist: event.fromWishlist,
      );

      emit(CartItemAdded(item));
      // Reload cart to get updated totals
      add(LoadActiveCart());
    } catch (e) {
      emit(CartError('Failed to add to cart: ${e.toString()}'));
    }
  }

  Future<void> _onRemoveFromCart(
    RemoveFromCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      if (state is! CartLoaded) {
        emit(const CartError('Cart not loaded'));
        return;
      }

      final cart = (state as CartLoaded).cart;
      await LearnerPortalApiService.removeFromCart(
        cartId: cart.id,
        itemId: event.itemId,
      );

      emit(CartItemRemoved(event.itemId));
      // Reload cart to get updated totals
      add(LoadActiveCart());
    } catch (e) {
      emit(CartError('Failed to remove from cart: ${e.toString()}'));
    }
  }

  Future<void> _onClearCart(
    ClearCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      if (state is! CartLoaded) {
        emit(const CartError('Cart not loaded'));
        return;
      }

      final cart = (state as CartLoaded).cart;
      await LearnerPortalApiService.clearCart(cart.id);

      emit(CartCleared());
      // Reload cart
      add(LoadActiveCart());
    } catch (e) {
      emit(CartError('Failed to clear cart: ${e.toString()}'));
    }
  }

  Future<void> _onCheckoutCart(
    CheckoutCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      if (state is! CartLoaded) {
        emit(const CartError('Cart not loaded'));
        return;
      }

      final cart = (state as CartLoaded).cart;

      if (cart.isEmpty) {
        emit(const CartError('Cannot checkout empty cart'));
        return;
      }

      final result = await LearnerPortalApiService.checkoutCart(
        cartId: cart.id,
        usePreviousCompanyDetails: event.usePreviousCompanyDetails,
        isCorporateEnrollment: event.isCorporateEnrollment,
      );

      emit(CartCheckoutReady(
        cartId: result['cart_id'] as int,
        orderId: result['order_id'] as String,
        totalAmount: result['total_amount'] as String,
        totalCourses: result['total_courses'] as int,
        currency: result['currency'] as String? ?? 'USD',
      ));
    } catch (e) {
      emit(CartError('Failed to checkout: ${e.toString()}'));
    }
  }
}
