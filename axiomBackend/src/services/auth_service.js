import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import {User} from '../models/User.js';
import { HTTP_STATUS, ERROR_MESSAGES } from '../config/constants.js';

class AuthService {
  static async generateToken(userId) {
    return jwt.sign(
      { userId },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );
  }

  static async verifyToken(token) {
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
      return decoded;
    } catch (error) {
      throw new Error('Invalid token');
    }
  }

  static async hashPassword(password) {
    const saltRounds = 12;
    return await bcrypt.hash(password, saltRounds);
  }

  static async comparePassword(password, hashedPassword) {
    return await bcrypt.compare(password, hashedPassword);
  }

  static async register(userData) {
    try {
      const { name, email, password } = userData;

      // Check if user already exists
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        throw new Error(ERROR_MESSAGES.USER_EXISTS);
      }

      // Hash password
      const hashedPassword = await this.hashPassword(password);

      // Create user
      const user = new User({
        name,
        email,
        password: hashedPassword,
      });

      await user.save();

      // Generate token
      const token = await this.generateToken(user._id);

      // Return user without password
      const userResponse = user.toObject();
      delete userResponse.password;

      return {
        user: userResponse,
        token,
      };
    } catch (error) {
      throw error;
    }
  }

  static async login(email, password) {
    try {
      // Find user by email
      const user = await User.findOne({ email });
      if (!user) {
        throw new Error(ERROR_MESSAGES.INVALID_CREDENTIALS);
      }

      // Compare password
      const isPasswordValid = await this.comparePassword(password, user.password);
      if (!isPasswordValid) {
        throw new Error(ERROR_MESSAGES.INVALID_CREDENTIALS);
      }

      // Generate token
      const token = await this.generateToken(user._id);

      // Return user without password
      const userResponse = user.toObject();
      delete userResponse.password;

      return {
        user: userResponse,
        token,
      };
    } catch (error) {
      throw error;
    }
  }

  static async getUserById(userId) {
    try {
      const user = await User.findById(userId).select('-password');
      if (!user) {
        throw new Error(ERROR_MESSAGES.NOT_FOUND);
      }
      return user;
    } catch (error) {
      throw error;
    }
  }

  static async updateUser(userId, updateData) {
    try {
      // Don't allow password update through this method
      if (updateData.password) {
        delete updateData.password;
      }

      const user = await User.findByIdAndUpdate(
        userId,
        updateData,
        { new: true, runValidators: true }
      ).select('-password');

      if (!user) {
        throw new Error(ERROR_MESSAGES.NOT_FOUND);
      }

      return user;
    } catch (error) {
      throw error;
    }
  }

  static async changePassword(userId, currentPassword, newPassword) {
    try {
      // Find user
      const user = await User.findById(userId);
      if (!user) {
        throw new Error(ERROR_MESSAGES.NOT_FOUND);
      }

      // Verify current password
      const isCurrentPasswordValid = await this.comparePassword(currentPassword, user.password);
      if (!isCurrentPasswordValid) {
        throw new Error('Current password is incorrect');
      }

      // Hash new password
      const hashedNewPassword = await this.hashPassword(newPassword);

      // Update password
      user.password = hashedNewPassword;
      await user.save();

      return true;
    } catch (error) {
      throw error;
    }
  }

  static async deleteUser(userId) {
    try {
      const user = await User.findByIdAndDelete(userId);
      if (!user) {
        throw new Error(ERROR_MESSAGES.NOT_FOUND);
      }
      return true;
    } catch (error) {
      throw error;
    }
  }
}

export default AuthService;
