import { HTTP_STATUS } from '../config/constants.js';
import ResponseHelper from '../utils/response_helper.js';

class ErrorHandler {
  static handle(err, req, res, next) {
    console.error('Error occurred:', {
      message: err.message,
      stack: err.stack,
      url: req.url,
      method: req.method,
      timestamp: new Date().toISOString(),
    });

    // Mongoose validation error
    if (err.name === 'ValidationError') {
      const errors = Object.values(err.errors).map(e => ({
        field: e.path,
        message: e.message,
      }));
      return ResponseHelper.validationError(res, errors);
    }

    // Mongoose duplicate key error
    if (err.code === 11000) {
      const field = Object.keys(err.keyValue)[0];
      const message = `${field} already exists`;
      return ResponseHelper.conflict(res, message);
    }

    // Mongoose cast error
    if (err.name === 'CastError') {
      return ResponseHelper.badRequest(res, 'Invalid ID format');
    }

    // JWT errors
    if (err.name === 'JsonWebTokenError') {
      return ResponseHelper.unauthorized(res, 'Invalid token');
    }

    if (err.name === 'TokenExpiredError') {
      return ResponseHelper.unauthorized(res, 'Token expired');
    }

    // Syntax error (invalid JSON)
    if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
      return ResponseHelper.badRequest(res, 'Invalid JSON format');
    }

    // Default error
    return ResponseHelper.serverError(res, err);
  }

  static notFound(req, res) {
    return ResponseHelper.notFound(res, `Route ${req.method} ${req.path} not found`);
  }

  static asyncWrapper(fn) {
    return (req, res, next) => {
      Promise.resolve(fn(req, res, next)).catch(next);
    };
  }
}

export default ErrorHandler;
