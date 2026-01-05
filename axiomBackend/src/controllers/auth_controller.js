import AuthService from '../services/auth_service.js';
import Validator from '../utils/validator.js';
import ResponseHelper from '../utils/response_helper.js';
import { HTTP_STATUS, SUCCESS_MESSAGES } from '../config/constants.js';

class AuthController {
  static async register(req, res) {
    try {
      const { name, email, password } = req.body;

      // Validate input
      const validationErrors = Validator.validateUser({ name, email, password });
      if (validationErrors) {
        return ResponseHelper.validationError(res, validationErrors);
      }

      // Register user
      const result = await AuthService.register({ name, email, password });

      return ResponseHelper.created(
        res,
        result,
        SUCCESS_MESSAGES.USER_CREATED
      );
    } catch (error) {
      return ResponseHelper.error(res, error.message, HTTP_STATUS.BAD_REQUEST);
    }
  }

  static async login(req, res) {
    try {
      const { email, password } = req.body;

      // Validate input
      const errors = {};
      
      const emailError = Validator.validateEmail(email);
      if (emailError) errors.email = emailError;

      const passwordError = Validator.validatePassword(password);
      if (passwordError) errors.password = passwordError;

      if (Object.keys(errors).length > 0) {
        return ResponseHelper.validationError(res, errors);
      }

      // Login user
      const result = await AuthService.login(email, password);

      return ResponseHelper.success(
        res,
        result,
        SUCCESS_MESSAGES.USER_LOGIN
      );
    } catch (error) {
      return ResponseHelper.unauthorized(res, error.message);
    }
  }

  static async getProfile(req, res) {
    try {
      const userId = req.userId;
      const user = await AuthService.getUserById(userId);

      return ResponseHelper.success(res, { user });
    } catch (error) {
      return ResponseHelper.notFound(res, error.message);
    }
  }

  static async updateProfile(req, res) {
    try {
      const userId = req.userId;
      const { name, email } = req.body;

      // Validate input
      const errors = {};

      if (name) {
        const nameError = Validator.validateName(name);
        if (nameError) errors.name = nameError;
      }

      if (email) {
        const emailError = Validator.validateEmail(email);
        if (emailError) errors.email = emailError;
      }

      if (Object.keys(errors).length > 0) {
        return ResponseHelper.validationError(res, errors);
      }

      const updatedUser = await AuthService.updateUser(userId, { name, email });

      return ResponseHelper.success(
        res,
        { user: updatedUser },
        'Profile updated successfully'
      );
    } catch (error) {
      return ResponseHelper.error(res, error.message);
    }
  }

  static async changePassword(req, res) {
    try {
      const userId = req.userId;
      const { currentPassword, newPassword } = req.body;

      // Validate input
      const errors = {};

      const currentPasswordError = Validator.validateRequired(currentPassword, 'Current password');
      if (currentPasswordError) errors.currentPassword = currentPasswordError;

      const newPasswordError = Validator.validatePassword(newPassword);
      if (newPasswordError) errors.newPassword = newPasswordError;

      if (Object.keys(errors).length > 0) {
        return ResponseHelper.validationError(res, errors);
      }

      await AuthService.changePassword(userId, currentPassword, newPassword);

      return ResponseHelper.success(res, null, 'Password changed successfully');
    } catch (error) {
      return ResponseHelper.error(res, error.message);
    }
  }

  static async logout(req, res) {
    try {
      // In a real implementation, you might want to:
      // 1. Add the token to a blacklist
      // 2. Clear any session data
      // 3. Handle client-side token removal

      return ResponseHelper.success(
        res,
        null,
        SUCCESS_MESSAGES.USER_LOGOUT
      );
    } catch (error) {
      return ResponseHelper.serverError(res, error);
    }
  }
}

export default AuthController;
