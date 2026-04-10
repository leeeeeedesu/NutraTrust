// Firebase authentication service

import firebase from 'firebase/app';
import 'firebase/auth';

const firebaseConfig = {
    apiKey: 'YOUR_API_KEY',
    authDomain: 'YOUR_AUTH_DOMAIN',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    appId: 'YOUR_APP_ID'
};

// Initialize Firebase
if (!firebase.apps.length) {
    firebase.initializeApp(firebaseConfig);
}

// Register new user
export const register = async (email, password) => {
    return await firebase.auth().createUserWithEmailAndPassword(email, password);
};

// Login user
export const login = async (email, password) => {
    return await firebase.auth().signInWithEmailAndPassword(email, password);
};

// Logout user
export const logout = async () => {
    return await firebase.auth().signOut();
};

// Get current user data
export const getUserData = () => {
    return firebase.auth().currentUser;
};

// Update user profile
export const updateProfile = async (displayName, photoURL) => {
    const user = getUserData();
    return await user.updateProfile({
        displayName,
        photoURL
    });
};