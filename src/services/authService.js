const User = require('../models/User');

class AuthService {
    async register(userData) {
        const user = new User(userData);
        await user.save();
        return user;
    }

    async login(username, password) {
        const user = await User.findOne({ username });
        if (!user || !(await user.comparePassword(password))) {
            throw new Error('Invalid username or password');
        }
        return user;
    }

    async logout(userId) {
        // Clear user session or token logic here
        return true;
    }

    async getProfile(userId) {
        const user = await User.findById(userId);
        return user;
    }
}

module.exports = new AuthService();