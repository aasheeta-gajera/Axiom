import { HTTP_STATUS, ERROR_MESSAGES, SUCCESS_MESSAGES } from '../config/constants.js';

class ResponseHelper {
  static success(res, data = null, message = null, statusCode = HTTP_STATUS.OK) {
    const response = {
      success: true,
      status: statusCode,
      message: message || 'Operation successful',
    };

    if (data !== null) {
      response.data = data;
    }

    return res.status(statusCode).json(response);
  }

  static created(res, data = null, message = null) {
    return this.success(
      res,
      data,
      message || SUCCESS_MESSAGES.CREATED || 'Resource created successfully',
      HTTP_STATUS.CREATED
    );
  }

  static noContent(res, message = null) {
    return res.status(HTTP_STATUS.NO_CONTENT).json({
      success: true,
      status: HTTP_STATUS.NO_CONTENT,
      message: message || 'Operation completed successfully',
    });
  }

  static error(res, message = null, statusCode = HTTP_STATUS.INTERNAL_SERVER_ERROR, error = null) {
    const response = {
      success: false,
      status: statusCode,
      message: message || ERROR_MESSAGES.INTERNAL_ERROR,
    };

    if (error && process.env.NODE_ENV === 'development') {
      response.error = {
        name: error.name,
        message: error.message,
        stack: error.stack,
      };
    }

    return res.status(statusCode).json(response);
  }

  static badRequest(res, message = null, errors = null) {
    const response = {
      success: false,
      status: HTTP_STATUS.BAD_REQUEST,
      message: message || ERROR_MESSAGES.VALIDATION_ERROR,
    };

    if (errors) {
      response.errors = errors;
    }

    return res.status(HTTP_STATUS.BAD_REQUEST).json(response);
  }

  static unauthorized(res, message = null) {
    return this.error(
      res,
      message || ERROR_MESSAGES.UNAUTHORIZED,
      HTTP_STATUS.UNAUTHORIZED
    );
  }

  static forbidden(res, message = null) {
    return this.error(
      res,
      message || ERROR_MESSAGES.FORBIDDEN,
      HTTP_STATUS.FORBIDDEN
    );
  }

  static notFound(res, message = null) {
    return this.error(
      res,
      message || ERROR_MESSAGES.NOT_FOUND,
      HTTP_STATUS.NOT_FOUND
    );
  }

  static conflict(res, message = null) {
    return this.error(
      res,
      message || ERROR_MESSAGES.CONFLICT,
      HTTP_STATUS.CONFLICT
    );
  }

  static unprocessableEntity(res, message = null, errors = null) {
    const response = {
      success: false,
      status: HTTP_STATUS.UNPROCESSABLE_ENTITY,
      message: message || ERROR_MESSAGES.VALIDATION_ERROR,
    };

    if (errors) {
      response.errors = errors;
    }

    return res.status(HTTP_STATUS.UNPROCESSABLE_ENTITY).json(response);
  }

  static paginated(res, data, pagination, message = null) {
    return this.success(res, {
      items: data,
      pagination: {
        page: pagination.page,
        limit: pagination.limit,
        total: pagination.total,
        pages: Math.ceil(pagination.total / pagination.limit),
        hasNext: pagination.page < Math.ceil(pagination.total / pagination.limit),
        hasPrev: pagination.page > 1,
      },
    }, message);
  }

  static validationError(res, errors) {
    return this.badRequest(res, ERROR_MESSAGES.VALIDATION_ERROR, errors);
  }

  static databaseError(res, error) {
    console.error('Database error:', error);
    return this.error(res, ERROR_MESSAGES.DATABASE_ERROR, HTTP_STATUS.INTERNAL_SERVER_ERROR, error);
  }

  static serverError(res, error) {
    console.error('Server error:', error);
    return this.error(res, ERROR_MESSAGES.INTERNAL_ERROR, HTTP_STATUS.INTERNAL_SERVER_ERROR, error);
  }
}

export default ResponseHelper;
