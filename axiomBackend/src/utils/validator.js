import { VALIDATION_RULES, ERROR_MESSAGES } from '../config/constants.js';

class Validator {
  static validateEmail(email) {
    if (!email) {
      return ERROR_MESSAGES.EMAIL_REQUIRED;
    }

    if (!VALIDATION_RULES.EMAIL_PATTERN.test(email)) {
      return ERROR_MESSAGES.INVALID_EMAIL;
    }

    return null;
  }

  static validatePassword(password) {
    if (!password) {
      return ERROR_MESSAGES.PASSWORD_REQUIRED;
    }

    if (password.length < VALIDATION_RULES.PASSWORD_MIN_LENGTH) {
      return ERROR_MESSAGES.PASSWORD_TOO_SHORT;
    }

    return null;
  }

  static validateName(name) {
    if (!name) {
      return ERROR_MESSAGES.NAME_REQUIRED;
    }

    if (name.length < VALIDATION_RULES.NAME_MIN_LENGTH) {
      return 'Name must be at least 2 characters long';
    }

    if (name.length > VALIDATION_RULES.NAME_MAX_LENGTH) {
      return 'Name must be less than 50 characters long';
    }

    return null;
  }

  static validateProjectName(name) {
    if (!name) {
      return 'Project name is required';
    }

    if (name.length < VALIDATION_RULES.PROJECT_NAME_MIN_LENGTH) {
      return 'Project name must be at least 3 characters long';
    }

    if (name.length > VALIDATION_RULES.PROJECT_NAME_MAX_LENGTH) {
      return 'Project name must be less than 50 characters long';
    }

    return null;
  }

  static validateApiPath(path) {
    if (!path) {
      return 'API path is required';
    }

    if (!path.startsWith('/')) {
      return 'API path must start with /';
    }

    if (!VALIDATION_RULES.API_PATH_PATTERN.test(path)) {
      return 'API path can only contain letters, numbers, hyphens, and underscores';
    }

    return null;
  }

  static validateRequired(value, fieldName) {
    if (!value || (typeof value === 'string' && value.trim() === '')) {
      return `${fieldName} is required`;
    }

    return null;
  }

  static validateObjectId(id) {
    if (!id) {
      return 'ID is required';
    }

    const objectIdPattern = /^[0-9a-fA-F]{24}$/;
    if (!objectIdPattern.test(id)) {
      return 'Invalid ID format';
    }

    return null;
  }

  static validateEnum(value, allowedValues, fieldName) {
    if (!allowedValues.includes(value)) {
      return `${fieldName} must be one of: ${allowedValues.join(', ')}`;
    }

    return null;
  }

  static validateArray(value, fieldName) {
    if (!Array.isArray(value)) {
      return `${fieldName} must be an array`;
    }

    return null;
  }

  static validateObject(value, fieldName) {
    if (typeof value !== 'object' || value === null || Array.isArray(value)) {
      return `${fieldName} must be an object`;
    }

    return null;
  }

  static validateString(value, fieldName, minLength = 0, maxLength = null) {
    if (typeof value !== 'string') {
      return `${fieldName} must be a string`;
    }

    if (value.length < minLength) {
      return `${fieldName} must be at least ${minLength} characters long`;
    }

    if (maxLength && value.length > maxLength) {
      return `${fieldName} must be less than ${maxLength} characters long`;
    }

    return null;
  }

  static validateNumber(value, fieldName, min = null, max = null) {
    if (typeof value !== 'number' || isNaN(value)) {
      return `${fieldName} must be a number`;
    }

    if (min !== null && value < min) {
      return `${fieldName} must be at least ${min}`;
    }

    if (max !== null && value > max) {
      return `${fieldName} must be at most ${max}`;
    }

    return null;
  }

  static validateBoolean(value, fieldName) {
    if (typeof value !== 'boolean') {
      return `${fieldName} must be a boolean`;
    }

    return null;
  }

  static validateUrl(url) {
    if (!url) {
      return 'URL is required';
    }

    try {
      new URL(url);
      return null;
    } catch (error) {
      return 'Invalid URL format';
    }
  }

  static validateDate(date, fieldName) {
    if (!date) {
      return `${fieldName} is required`;
    }

    const dateObj = new Date(date);
    if (isNaN(dateObj.getTime())) {
      return `${fieldName} must be a valid date`;
    }

    return null;
  }

  static validateUser(userData) {
    const errors = {};

    const nameError = this.validateName(userData.name);
    if (nameError) errors.name = nameError;

    const emailError = this.validateEmail(userData.email);
    if (emailError) errors.email = emailError;

    const passwordError = this.validatePassword(userData.password);
    if (passwordError) errors.password = passwordError;

    return Object.keys(errors).length > 0 ? errors : null;
  }

  static validateProject(projectData) {
    const errors = {};

    const nameError = this.validateProjectName(projectData.name);
    if (nameError) errors.name = nameError;

    if (projectData.description && typeof projectData.description !== 'string') {
      errors.description = 'Description must be a string';
    }

    return Object.keys(errors).length > 0 ? errors : null;
  }

  static validateApiEndpoint(endpointData) {
    const errors = {};

    const nameError = this.validateRequired(endpointData.name, 'API name');
    if (nameError) errors.name = nameError;

    const methodError = this.validateEnum(
      endpointData.method,
      ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
      'API method'
    );
    if (methodError) errors.method = methodError;

    const pathError = this.validateApiPath(endpointData.path);
    if (pathError) errors.path = pathError;

    return Object.keys(errors).length > 0 ? errors : null;
  }

  static validateWidget(widgetData) {
    const errors = {};

    const typeError = this.validateRequired(widgetData.type, 'Widget type');
    if (typeError) errors.type = typeError;

    const idError = this.validateRequired(widgetData.id, 'Widget ID');
    if (idError) errors.id = idError;

    if (widgetData.properties) {
      const propertiesError = this.validateObject(widgetData.properties, 'Properties');
      if (propertiesError) errors.properties = propertiesError;
    }

    return Object.keys(errors).length > 0 ? errors : null;
  }
}

export default Validator;
