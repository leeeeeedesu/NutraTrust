# Firebase Rules Finalization - E-Commerce App

## Executive Summary

This document finalizes the Firebase Realtime Database implementation for the NutraTrust e-commerce app, ensuring complete overselling prevention, stock management, and integrated features (reviews, vouchers, seller messages).

---

## 1. Firebase Rules (firebase_rules.json)

### Products Section
```
"products": {
  ".read": "auth != null",
  ".write": "root.child('users').child(auth.uid).child('role').val() === 'admin'",
  "$productId": {
    ".validate": "newData.hasChildren(['name', 'price', 'stock'])",
    "stock": {
      ".write": "root.child('users').child(auth.uid).child('role').val() === 'admin' || (newData.val() <= data.val())",
      ".validate": "newData.isNumber() && newData.val() >= 0"
    }
    // ... other fields
  }
}
```

**Rules:**
- Admins: Full write access to all product fields
- Customers: Can only decrement stock (new stock ≤ old stock)
- Stock: Non-negative, immutable except for admin and decrement operations

### Orders Section
```
"orders": {
  "$orderId": {
    ".validate": "newData.hasChildren(['userId','productId','quantity','totalPrice'])",
    "quantity": { 
      ".validate": "newData.isNumber() && newData.val() > 0 && newData.val() <= root.child('products').child(newData.parent.child('productId').val()).child('stock').val()"
    },
    "reviewed": { ".validate": "newData.isBoolean()" },
    "messageForSeller": { ".validate": "newData.isString() || !newData.exists()" },
    "voucherCode": { ".validate": "newData.isString() || !newData.exists()" },
    // ... other validations
  }
}
```

**Rules:**
- Quantity must be > 0
- Quantity must not exceed available product stock
- Reviewed field tracks if order has been reviewed (boolean)
- messageForSeller and voucherCode fields for customer communication

---

## 2. Stock Management Service (realtime_database_service.dart)

### decrementProductStock() Method

**Features:**
- **Atomic Transaction**: Uses Firebase `runTransaction()` for race condition prevention
- **Stock Verification**: Fetches current stock before decrement
- **Conditional Abort**: Aborts if requested quantity exceeds available stock
- **Comprehensive Logging**: Detailed debug output for troubleshooting

**Debug Logging:**
```
// Pre-transaction
"Requested quantity: 2 for productId: prod123"

// During transaction
"Available stock: 10 for productId: prod123"

// On insufficient stock (abort)
"Insufficient stock: Available 5, Requested 10 for productId: prod123"

// On success
"Stock decremented successfully for productId: prod123, new stock: 8"

// On failure
"Stock decrement failed (transaction aborted) for productId: prod123"
```

### getProductStock() Method

**Features:**
- Retrieves current stock for a product
- Used in checkout_page.dart for pre-checkout validation
- Returns 0 if product not found

---

## 3. Checkout Flow (checkout_page.dart)

**Stock Validation Workflow:**

```
User clicks "Checkout"
  ↓
Check profile complete ✓
  ↓
For each item:
  → Fetch current stock via getProductStock()
  → Log "Requested quantity: X, Available stock: Y"
  → If requested > available:
      • Log "Order rejected due to insufficient stock"
      • Show error snackbar
      • Return without creating order
  ↓
Create order via createOrder()
  → Calls decrementProductStock() internally
  → Stock decremented atomically via transaction
  → Log "Order placed, stock updated" on success
  ↓
Show success screen
```

**Debug Output Example:**
```
✓ Requested quantity: 3 for productId: prod_456
✓ Available stock: 10 for productId: prod_456
✓ Available stock: 5 for productId: prod_789
✓ Stock decremented successfully for productId: prod_456, new stock: 7
✓ Stock decremented successfully for productId: prod_789, new stock: 2
✓ Order placed, stock updated
```

---

## 4. Admin Dashboard (admin_dashboard.dart & admin_inventory.dart)

### Dashboard Display
- **Products List**: Shows stock count with status
  - "Out of Stock" (stock == 0) - Red
  - "Low Stock" (0 < stock ≤ 5) - Orange
  - "In Stock" (stock > 5) - Green

### Inventory Management
- **Stock Tags**: Visual indicators for inventory status
- **Real-Time Updates**: StreamBuilder automatically updates on stock changes
- **Color Coding**: 
  - Red backgrounds/text for no stock
  - Orange for low stock
  - Green for healthy stock

**Example Display:**
```
Product: Nutella Spread
Stock: 0 • Out of Stock  [Red badge]

Product: Almond Milk
Stock: 3 • Low Stock     [Orange badge]

Product: Protein Powder
Stock: 25 • In Stock     [Green badge]
```

---

## 5. Product View (view_product_page.dart)

### Client-Side Quantity Capping

**Features:**
- Prevents quantity selection beyond available stock
- Shows warning when limit reached
- Applied to both "Add to Cart" and "Buy Now" flows

**User Experience:**
```
User increases quantity to max stock
  ↓
Button pressed → Check: quantity >= stock?
  → If YES: Show snackbar "Only X items available"
           Cancel quantity increase
  → If NO:  Increment quantity normally
```

---

## 6. Review System Integration

**Existing Features Maintained:**
- `reviewed` field: Boolean flag (0 = unreviewed, 1 = reviewed)
- Only shows review button for delivered, unreviewed orders
- Review submission only for customers who purchased the product
- Admin can override review status

---

## 7. Voucher & Seller Message Integration

**Features Maintained:**
- `voucherCode` field: Stores applied voucher code
- `messageForSeller` field: Customer message during checkout
- Both fields optional (empty string or not present = no value)
- Validated in Firebase rules as strings

---

## Testing Checklist

### Stock Validation
- [ ] User can't add more items than available in product view
- [ ] User can't proceed to checkout if quantity exceeds stock
- [ ] Error messages display correctly for insufficient stock
- [ ] Debug logs show request/available quantities

### Stock Decrement
- [ ] Stock decrements after successful order
- [ ] Stock decrements atomically (no race conditions)
- [ ] Stock updates visible in admin dashboard immediately
- [ ] Stock tags update (Out of Stock/Low Stock/In Stock)

### Admin Monitoring
- [ ] Dashboard shows current stock for all products
- [ ] Stock status indicators display correctly
- [ ] "Out of Stock" items clearly marked in red
- [ ] Inventory page shows detailed stock information

### Integration
- [ ] Reviews can be submitted for delivered orders
- [ ] Vouchers are saved with orders
- [ ] Seller messages are saved with orders
- [ ] All fields persist in Firebase

### Logging
- [ ] "Requested quantity: X" logs before checkout
- [ ] "Available stock: Y" logs before checkout
- [ ] "Stock decremented successfully" logs after checkout
- [ ] "Insufficient stock" logs when transaction aborts

---

## Deployment Notes

1. **Firebase Rules Deployment**: Update Firebase Realtime Database rules in console
2. **Code Deployment**: Deploy Flutter app with all service and UI updates
3. **Admin Access**: Ensure admin users have 'role' = 'admin' in users database
4. **Stock Migration**: Set initial stock values for all products before go-live

---

## Result

✅ **Customers** can only purchase available stock with clear validation
✅ **Orders** decrement stock atomically, preventing overselling
✅ **Admins** monitor stock in real-time with visual indicators
✅ **Integration** of reviews, vouchers, and seller messages complete
✅ **Logging** provides detailed debugging information for troubleshooting
