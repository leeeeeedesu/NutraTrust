import { db } from '../config/firebaseConfig';
import { cartService } from './cartService';

export const orderService = {
  // Create order from cart
  async createOrder(userId, shippingAddress) {
    try {
      // Get cart items
      const { success: cartSuccess, data: cartItems } = await cartService.getCartItems(userId);
      if (!cartSuccess || cartItems.length === 0) {
        return { success: false, error: 'Cart is empty' };
      }

      // Calculate total
      const total = cartItems.reduce((sum, item) => sum + item.price * item.quantity, 0);

      // Create order document
      const orderRef = await db.collection('orders').add({
        userId,
        items: cartItems,
        total,
        subtotal: total,
        tax: parseFloat((total * 0.1).toFixed(2)),
        shippingAddress,
        status: 'pending',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });

      // Clear cart after order
      await cartService.clearCart(userId);

      return { success: true, orderId: orderRef.id };
    } catch (error) {
      return { success: false, error: error.message };
    }
  },

  // Get user orders
  async getUserOrders(userId) {
    try {
      const snapshot = await db
        .collection('orders')
        .where('userId', '==', userId)
        .orderBy('createdAt', 'desc')
        .get();
      const orders = [];
      snapshot.forEach(doc => {
        orders.push({ id: doc.id, ...doc.data() });
      });
      return { success: true, data: orders };
    } catch (error) {
      return { success: false, error: error.message };
    }
  },

  // Get single order
  async getOrder(orderId) {
    try {
      const doc = await db.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return { success: true, data: { id: doc.id, ...doc.data() } };
      }
      return { success: false, error: 'Order not found' };
    } catch (error) {
      return { success: false, error: error.message };
    }
  },

  // Update order status
  async updateOrderStatus(orderId, status) {
    try {
      await db.collection('orders').doc(orderId).update({
        status,
        updatedAt: new Date().toISOString(),
      });
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  },

  // Cancel order
  async cancelOrder(orderId) {
    try {
      await db.collection('orders').doc(orderId).update({
        status: 'cancelled',
        updatedAt: new Date().toISOString(),
      });
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  },
};