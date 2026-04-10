// src/services/storageService.js

import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { initializeApp } from "firebase/app";

// Your web app's Firebase configuration
const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_AUTH_DOMAIN",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_STORAGE_BUCKET",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID"
};
// Initialize Firebase
const app = initializeApp(firebaseConfig);
const storage = getStorage(app);

// Function to upload files
export const uploadFile = async (file, path) => {
    const storageRef = ref(storage, path);
    try {
        await uploadBytes(storageRef, file);
        const fileURL = await getDownloadURL(storageRef);
        return fileURL;
    } catch (error) {
        console.error("Error uploading file:", error);
        throw error;
    }
};

// Function to retrieve file URL
export const getFileURL = async (path) => {
    const storageRef = ref(storage, path);
    try {
        const url = await getDownloadURL(storageRef);
        return url;
    } catch (error) {
        console.error("Error getting file URL:", error);
        throw error;
    }
};