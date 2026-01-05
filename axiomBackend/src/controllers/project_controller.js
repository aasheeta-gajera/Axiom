import ProjectService from '../services/project_service.js';
import Validator from '../utils/validator.js';
import ResponseHelper from '../utils/response_helper.js';
import { HTTP_STATUS, SUCCESS_MESSAGES, PAGINATION } from '../config/constants.js';

class ProjectController {
  static async createProject(req, res) {
    try {
      const userId = req.userId;
      const { name, description } = req.body;

      // Validate input
      const validationErrors = Validator.validateProject({ name, description });
      if (validationErrors) {
        return ResponseHelper.validationError(res, validationErrors);
      }

      // Create project
      const project = await ProjectService.createProject(
        { name, description },
        userId
      );

      return ResponseHelper.created(
        res,
        project,
        SUCCESS_MESSAGES.PROJECT_CREATED
      );
    } catch (error) {
      return ResponseHelper.error(res, error.message);
    }
  }

  static async getProjects(req, res) {
    try {
      const userId = req.userId;
      const {
        page = PAGINATION.DEFAULT_PAGE,
        limit = PAGINATION.DEFAULT_LIMIT,
        all = false,
      } = req.query;

      // Validate pagination parameters
      const pageNum = parseInt(page);
      const limitNum = parseInt(limit);

      if (isNaN(pageNum) || pageNum < 1) {
        return ResponseHelper.badRequest(res, 'Invalid page number');
      }

      if (isNaN(limitNum) || limitNum < 1 || limitNum > PAGINATION.MAX_LIMIT) {
        return ResponseHelper.badRequest(res, 'Invalid limit number');
      }

      const options = {
        page: pageNum,
        limit: limitNum,
        all: all === 'true',
      };

      const result = await ProjectService.getProjects(userId, options);

      return ResponseHelper.paginated(
        res,
        result.projects,
        result.pagination,
        'Projects retrieved successfully'
      );
    } catch (error) {
      return ResponseHelper.error(res, error.message);
    }
  }

  static async getProject(req, res) {
    try {
      const userId = req.userId;
      const { projectId } = req.params;

      // Validate project ID
      const idError = Validator.validateObjectId(projectId);
      if (idError) {
        return ResponseHelper.badRequest(res, idError);
      }

      const project = await ProjectService.getProjectById(projectId, userId);

      return ResponseHelper.success(res, project);
    } catch (error) {
      if (error.message.includes('not found')) {
        return ResponseHelper.notFound(res, error.message);
      }
      if (error.message.includes('forbidden')) {
        return ResponseHelper.forbidden(res, error.message);
      }
      return ResponseHelper.error(res, error.message);
    }
  }

  static async updateProject(req, res) {
    try {
      const userId = req.userId;
      const { projectId } = req.params;
      const { name, description } = req.body;

      // Validate project ID
      const idError = Validator.validateObjectId(projectId);
      if (idError) {
        return ResponseHelper.badRequest(res, idError);
      }

      // Validate input
      const validationErrors = Validator.validateProject({ name, description });
      if (validationErrors) {
        return ResponseHelper.validationError(res, validationErrors);
      }

      const updatedProject = await ProjectService.updateProject(
        projectId,
        userId,
        { name, description }
      );

      return ResponseHelper.success(
        res,
        updatedProject,
        SUCCESS_MESSAGES.PROJECT_UPDATED
      );
    } catch (error) {
      if (error.message.includes('not found')) {
        return ResponseHelper.notFound(res, error.message);
      }
      if (error.message.includes('forbidden')) {
        return ResponseHelper.forbidden(res, error.message);
      }
      return ResponseHelper.error(res, error.message);
    }
  }

  static async deleteProject(req, res) {
    try {
      const userId = req.userId;
      const { projectId } = req.params;

      // Validate project ID
      const idError = Validator.validateObjectId(projectId);
      if (idError) {
        return ResponseHelper.badRequest(res, idError);
      }

      await ProjectService.deleteProject(projectId, userId);

      return ResponseHelper.success(
        res,
        null,
        SUCCESS_MESSAGES.PROJECT_DELETED
      );
    } catch (error) {
      if (error.message.includes('not found')) {
        return ResponseHelper.notFound(res, error.message);
      }
      if (error.message.includes('forbidden')) {
        return ResponseHelper.forbidden(res, error.message);
      }
      return ResponseHelper.error(res, error.message);
    }
  }

  static async addCollaborator(req, res) {
    try {
      const userId = req.userId;
      const { projectId } = req.params;
      const { email } = req.body;

      // Validate project ID
      const idError = Validator.validateObjectId(projectId);
      if (idError) {
        return ResponseHelper.badRequest(res, idError);
      }

      // Validate email
      const emailError = Validator.validateEmail(email);
      if (emailError) {
        return ResponseHelper.validationError(res, { email: emailError });
      }

      const updatedProject = await ProjectService.addCollaborator(
        projectId,
        userId,
        email
      );

      return ResponseHelper.success(
        res,
        updatedProject,
        'Collaborator added successfully'
      );
    } catch (error) {
      if (error.message.includes('not found')) {
        return ResponseHelper.notFound(res, error.message);
      }
      if (error.message.includes('forbidden')) {
        return ResponseHelper.forbidden(res, error.message);
      }
      return ResponseHelper.error(res, error.message);
    }
  }

  static async removeCollaborator(req, res) {
    try {
      const userId = req.userId;
      const { projectId, collaboratorId } = req.params;

      // Validate IDs
      const projectIdError = Validator.validateObjectId(projectId);
      if (projectIdError) {
        return ResponseHelper.badRequest(res, projectIdError);
      }

      const collaboratorIdError = Validator.validateObjectId(collaboratorId);
      if (collaboratorIdError) {
        return ResponseHelper.badRequest(res, collaboratorIdError);
      }

      const updatedProject = await ProjectService.removeCollaborator(
        projectId,
        userId,
        collaboratorId
      );

      return ResponseHelper.success(
        res,
        updatedProject,
        'Collaborator removed successfully'
      );
    } catch (error) {
      if (error.message.includes('not found')) {
        return ResponseHelper.notFound(res, error.message);
      }
      if (error.message.includes('forbidden')) {
        return ResponseHelper.forbidden(res, error.message);
      }
      return ResponseHelper.error(res, error.message);
    }
  }

  static async addWidget(req, res) {
    try {
      const userId = req.userId;
      const { projectId } = req.params;
      const widgetData = req.body;

      // Validate project ID
      const idError = Validator.validateObjectId(projectId);
      if (idError) {
        return ResponseHelper.badRequest(res, idError);
      }

      // Validate widget data
      const widgetErrors = Validator.validateWidget(widgetData);
      if (widgetErrors) {
        return ResponseHelper.validationError(res, widgetErrors);
      }

      const updatedProject = await ProjectService.addWidget(
        projectId,
        userId,
        widgetData
      );

      return ResponseHelper.success(
        res,
        updatedProject,
        SUCCESS_MESSAGES.WIDGET_CREATED
      );
    } catch (error) {
      if (error.message.includes('not found')) {
        return ResponseHelper.notFound(res, error.message);
      }
      if (error.message.includes('forbidden')) {
        return ResponseHelper.forbidden(res, error.message);
      }
      return ResponseHelper.error(res, error.message);
    }
  }

  static async updateWidget(req, res) {
    try {
      const userId = req.userId;
      const { projectId, widgetId } = req.params;
      const widgetData = req.body;

      // Validate project ID
      const idError = Validator.validateObjectId(projectId);
      if (idError) {
        return ResponseHelper.badRequest(res, idError);
      }

      // Validate widget data
      const widgetErrors = Validator.validateWidget(widgetData);
      if (widgetErrors) {
        return ResponseHelper.validationError(res, widgetErrors);
      }

      const updatedProject = await ProjectService.updateWidget(
        projectId,
        userId,
        widgetId,
        widgetData
      );

      return ResponseHelper.success(
        res,
        updatedProject,
        SUCCESS_MESSAGES.WIDGET_UPDATED
      );
    } catch (error) {
      if (error.message.includes('not found')) {
        return ResponseHelper.notFound(res, error.message);
      }
      if (error.message.includes('forbidden')) {
        return ResponseHelper.forbidden(res, error.message);
      }
      return ResponseHelper.error(res, error.message);
    }
  }

  static async deleteWidget(req, res) {
    try {
      const userId = req.userId;
      const { projectId, widgetId } = req.params;

      // Validate project ID
      const idError = Validator.validateObjectId(projectId);
      if (idError) {
        return ResponseHelper.badRequest(res, idError);
      }

      const updatedProject = await ProjectService.deleteWidget(
        projectId,
        userId,
        widgetId
      );

      return ResponseHelper.success(
        res,
        updatedProject,
        SUCCESS_MESSAGES.WIDGET_DELETED
      );
    } catch (error) {
      if (error.message.includes('not found')) {
        return ResponseHelper.notFound(res, error.message);
      }
      if (error.message.includes('forbidden')) {
        return ResponseHelper.forbidden(res, error.message);
      }
      return ResponseHelper.error(res, error.message);
    }
  }
}

export default ProjectController;
