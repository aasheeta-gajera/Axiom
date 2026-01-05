export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  NO_CONTENT: 204,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  UNPROCESSABLE_ENTITY: 422,
  INTERNAL_SERVER_ERROR: 500,
  SERVICE_UNAVAILABLE: 503,
};

export const ERROR_MESSAGES = {
  VALIDATION_ERROR: 'Validation failed',
  UNAUTHORIZED: 'Unauthorized access',
  FORBIDDEN: 'Access forbidden',
  NOT_FOUND: 'Resource not found',
  CONFLICT: 'Resource conflict',
  INTERNAL_ERROR: 'Internal server error',
  DATABASE_ERROR: 'Database operation failed',
  INVALID_CREDENTIALS: 'Invalid email or password',
  TOKEN_EXPIRED: 'Token has expired',
  TOKEN_INVALID: 'Invalid token',
  USER_EXISTS: 'User already exists',
  PROJECT_NOT_FOUND: 'Project not found',
  WIDGET_NOT_FOUND: 'Widget not found',
  API_NOT_FOUND: 'API endpoint not found',
  INVALID_INPUT: 'Invalid input data',
  MISSING_REQUIRED_FIELD: 'Missing required field',
  INVALID_EMAIL: 'Invalid email format',
  PASSWORD_TOO_SHORT: 'Password must be at least 6 characters',
  NAME_REQUIRED: 'Name is required',
  EMAIL_REQUIRED: 'Email is required',
  PASSWORD_REQUIRED: 'Password is required',
};

export const SUCCESS_MESSAGES = {
  USER_CREATED: 'User created successfully',
  USER_LOGIN: 'Login successful',
  USER_LOGOUT: 'Logout successful',
  PROJECT_CREATED: 'Project created successfully',
  PROJECT_UPDATED: 'Project updated successfully',
  PROJECT_DELETED: 'Project deleted successfully',
  WIDGET_CREATED: 'Widget created successfully',
  WIDGET_UPDATED: 'Widget updated successfully',
  WIDGET_DELETED: 'Widget deleted successfully',
  API_CREATED: 'API endpoint created successfully',
  API_UPDATED: 'API endpoint updated successfully',
  API_DELETED: 'API endpoint deleted successfully',
};

export const WIDGET_TYPES = {
  CONTAINER: 'Container',
  TEXT: 'Text',
  BUTTON: 'Button',
  IMAGE: 'Image',
  CARD: 'Card',
  ROW: 'Row',
  COLUMN: 'Column',
  LISTVIEW: 'ListView',
  TEXTFIELD: 'TextField',
  APPBAR: 'AppBar',
  SCAFFOLD: 'Scaffold',
};

export const API_METHODS = {
  GET: 'GET',
  POST: 'POST',
  PUT: 'PUT',
  DELETE: 'DELETE',
  PATCH: 'PATCH',
};

export const EVENT_TYPES = {
  ON_CLICK: 'onClick',
  ON_CHANGE: 'onChange',
  ON_SUBMIT: 'onSubmit',
  ON_FOCUS: 'onFocus',
  ON_BLUR: 'onBlur',
  ON_LOAD: 'onLoad',
};

export const EVENT_ACTIONS = {
  NAVIGATE: 'navigate',
  API_CALL: 'apiCall',
  UPDATE_WIDGET: 'updateWidget',
  SHOW_DIALOG: 'showDialog',
  SHOW_SNACKBAR: 'showSnackBar',
  VALIDATE_FORM: 'validateForm',
  RESET_FORM: 'resetForm',
  SET_STATE: 'setState',
  REFRESH_DATA: 'refreshData',
};

export const FIELD_TYPES = {
  STRING: 'String',
  NUMBER: 'Number',
  BOOLEAN: 'Boolean',
  DATE: 'Date',
  OBJECT_ID: 'ObjectId',
  ARRAY: 'Array',
  OBJECT: 'Object',
  MIXED: 'Mixed',
};

export const COLLECTION_NAMES = {
  USERS: 'users',
  PROJECTS: 'projects',
  APIS: 'apis',
  WIDGETS: 'widgets',
};

export const API_PURPOSES = {
  LOGIN: 'login',
  REGISTER: 'register',
  CREATE: 'create',
  READ: 'read',
  UPDATE: 'update',
  DELETE: 'delete',
  LIST: 'list',
};

export const VALIDATION_RULES = {
  NAME_MIN_LENGTH: 2,
  NAME_MAX_LENGTH: 50,
  PASSWORD_MIN_LENGTH: 6,
  PROJECT_NAME_MIN_LENGTH: 3,
  PROJECT_NAME_MAX_LENGTH: 50,
  API_PATH_PATTERN: /^[a-zA-Z0-9\-_/]+$/,
  EMAIL_PATTERN: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
};

export const PAGINATION = {
  DEFAULT_PAGE: 1,
  DEFAULT_LIMIT: 10,
  MAX_LIMIT: 100,
};

export const CACHE_KEYS = {
  USER_PREFIX: 'user:',
  PROJECT_PREFIX: 'project:',
  API_PREFIX: 'api:',
  SESSION_PREFIX: 'session:',
};

export const SOCKET_EVENTS = {
  CONNECTION: 'connection',
  DISCONNECT: 'disconnect',
  JOIN_PROJECT: 'join-project',
  LEAVE_PROJECT: 'leave-project',
  WIDGET_UPDATE: 'widget-update',
  WIDGET_UPDATED: 'widget-updated',
  CURSOR_MOVE: 'cursor-move',
  CURSOR_MOVED: 'cursor-moved',
  PROJECT_UPDATE: 'project-update',
  PROJECT_UPDATED: 'project-updated',
};
