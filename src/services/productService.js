class ProductService {
    constructor() {
        this.products = [];
    }

    fetchProducts() {
        // Logic to fetch products from an API or database
        return this.products;
    }

    addProduct(product) {
        // Logic to add a new product
        this.products.push(product);
    }

    searchByCategory(category) {
        // Logic to search products by category
        return this.products.filter(product => product.category === category);
    }
}

export default new ProductService();