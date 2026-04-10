// Firebase product service code

import { db } from './firebaseConfig';
import { collection, getDocs, doc, getDoc, addDoc, updateDoc, deleteDoc, query, where } from 'firebase/firestore';

const productsCollection = collection(db, 'products');

// Get all products
export const getAllProducts = async () => {
    const productSnapshot = await getDocs(productsCollection);
    return productSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

// Get product by ID
export const getProduct = async (productId) => {
    const productDoc = doc(db, 'products', productId);
    const productData = await getDoc(productDoc);
    return productData.exists() ? { id: productData.id, ...productData.data() } : null;
};

// Add a new product
export const addProduct = async (productData) => {
    const docRef = await addDoc(productsCollection, productData);
    return { id: docRef.id, ...productData };
};

// Update product
export const updateProduct = async (productId, updatedData) => {
    const productDoc = doc(db, 'products', productId);
    await updateDoc(productDoc, updatedData);
    return { id: productId, ...updatedData };
};

// Delete product
export const deleteProduct = async (productId) => {
    const productDoc = doc(db, 'products', productId);
    await deleteDoc(productDoc);
    return { id: productId };
};

// Get products by category
export const getProductsByCategory = async (category) => {
    const categoryQuery = query(productsCollection, where('category', '==', category));
    const productSnapshot = await getDocs(categoryQuery);
    return productSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};
