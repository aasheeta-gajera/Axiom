import { Router } from 'express';
import AuthController from '../controllers/auth_controller.js';
import auth from '../middleware/auth.js';
import ErrorHandler from '../middleware/error_handler.js';

const router = Router();

// Public routes
router.post('/register', ErrorHandler.asyncWrapper(AuthController.register));
router.post('/login', ErrorHandler.asyncWrapper(AuthController.login));

// Protected routes
router.get('/profile', auth, ErrorHandler.asyncWrapper(AuthController.getProfile));
router.put('/profile', auth, ErrorHandler.asyncWrapper(AuthController.updateProfile));
router.put('/change-password', auth, ErrorHandler.asyncWrapper(AuthController.changePassword));
router.post('/logout', auth, ErrorHandler.asyncWrapper(AuthController.logout));

export default router;
