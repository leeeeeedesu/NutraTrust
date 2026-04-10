class CartService {
    constructor() {
        this.cart = [];
    }

    addToCart(item) {
        this.cart.push(item);
    }

    updateQuantity(itemId, quantity) {
        const item = this.cart.find(i => i.id === itemId);
        if (item) {
            item.quantity = quantity;
        }
    }

    removeItem(itemId) {
        this.cart = this.cart.filter(i => i.id !== itemId);
    }

    calculateTotal() {
        return this.cart.reduce((total, item) => total + (item.price * item.quantity), 0);
    }
}

// Example Usage:
// const cartService = new CartService();
// cartService.addToCart({id: 1, name: 'Product 1', price: 100, quantity: 1});
// console.log(cartService.calculateTotal()); // 100
