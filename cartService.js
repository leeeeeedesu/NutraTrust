import { db } from '../config/firebaseConfig';

export const cartService = {
    async addToCart(userId, product) {
        try {
            const cartItemId = `${product.id}_${Date.now()}`;
            await db.collection('carts').doc(userId).collection('items').doc(cartItemId).set({
                productId: product.id,
                name: product.name,
                price: product.price,
                imageUrl: product.imageUrl,
                quantity: 1,
                addedAt: new Date().toISOString(),
            });
            return { success: true, itemId: cartItemId };
        } catch (error) {
            return { success: false, error: error.message };
        }
    },

    async getCartItems(userId) {
        try {
            const snapshot = await db.collection('carts').doc(userId).collection('items').get();
            const items = [];
            snapshot.forEach(doc => {
                items.push({ id: doc.id, ...doc.data() });
            });
            return { success: true, data: items };
        } catch (error) {
            return { success: false, error: error.message };
        }
    },

    async updateQuantity(userId, itemId, quantity) {
        try {
            if (quantity <= 0) {
                return await this.removeFromCart(userId, itemId);
            }
            await db.collection('carts').doc(userId).collection('items').doc(itemId).update({ quantity });
            return { success: true };
        } catch (error) {
            return { success: false, error: error.message };
        }
    },

    async removeFromCart(userId, itemId) {
        try {
            await db.collection('carts').doc(userId).collection('items').doc(itemId).delete();
            return { success: true };
        } catch (error) {
            return { success: false, error: error.message };
        }
    },

    async clearCart(userId) {
        try {
            const snapshot = await db.collection('carts').doc(userId).collection('items').get();
            const batch = db.batch();
            snapshot.forEach(doc => {
                batch.delete(doc.ref);
            });
            await batch.commit();
            return { success: true };
        } catch (error) {
            return { success: false, error: error.message };
        }
    },

    async getCartTotal(userId) {
        try {
            const { success, data } = await this.getCartItems(userId);
            if (!success) throw new Error('Failed to fetch cart items');
            const total = data.reduce((sum, item) => sum + item.price * item.quantity, 0);
            return { success: true, total, itemCount: data.length };
        } catch (error) {
            return { success: false, error: error.message };
        }
    },
};