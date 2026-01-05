import { Project } from '../models/Project.js';
import { HTTP_STATUS, ERROR_MESSAGES, PAGINATION } from '../config/constants.js';

class ProjectService {
  static async createProject(projectData, owner) {
    try {
      const project = new Project({
        ...projectData,
        owner,
        widgets: [],
        screens: [{
          id: 'screen_1',
          name: 'Home',
          route: '/',
          widgets: []
        }]
      });

      await project.save();
      return project;
    } catch (error) {
      throw error;
    }
  }

  static async getProjects(userId, options = {}) {
    try {
      const {
        page = PAGINATION.DEFAULT_PAGE,
        limit = PAGINATION.DEFAULT_LIMIT,
        all = false,
      } = options;

      const skip = (page - 1) * limit;

      let query;
      if (all) {
        query = {};
      } else {
        query = {
          $or: [
            { owner: userId },
            { 'collaborators.user': userId }
          ]
        };
      }

      const projects = await Project.find(query)
        .populate('owner', 'name email')
        .populate('collaborators.user', 'name email')
        .sort({ updatedAt: -1 })
        .skip(skip)
        .limit(limit);

      const total = await Project.countDocuments(query);

      return {
        projects,
        pagination: {
          page,
          limit,
          total,
        }
      };
    } catch (error) {
      throw error;
    }
  }

  static async getProjectById(projectId, userId) {
    try {
      const project = await Project.findById(projectId)
        .populate('owner', 'name email')
        .populate('collaborators.user', 'name email');

      if (!project) {
        throw new Error(ERROR_MESSAGES.PROJECT_NOT_FOUND);
      }

      // Check if user has access to this project
      const hasAccess = project.owner._id.toString() === userId ||
                       project.collaborators.some(c => c.user._id.toString() === userId);

      if (!hasAccess) {
        throw new Error(ERROR_MESSAGES.FORBIDDEN);
      }

      return project;
    } catch (error) {
      throw error;
    }
  }

  static async updateProject(projectId, userId, updateData) {
    try {
      const project = await Project.findById(projectId);

      if (!project) {
        throw new Error(ERROR_MESSAGES.PROJECT_NOT_FOUND);
      }

      // Check if user is owner
      if (project.owner.toString() !== userId) {
        throw new Error(ERROR_MESSAGES.FORBIDDEN);
      }

      const updatedProject = await Project.findByIdAndUpdate(
        projectId,
        updateData,
        { new: true, runValidators: true }
      ).populate('owner', 'name email')
       .populate('collaborators.user', 'name email');

      return updatedProject;
    } catch (error) {
      throw error;
    }
  }

  static async deleteProject(projectId, userId) {
    try {
      const project = await Project.findById(projectId);

      if (!project) {
        throw new Error(ERROR_MESSAGES.PROJECT_NOT_FOUND);
      }

      // Check if user is owner
      if (project.owner.toString() !== userId) {
        throw new Error(ERROR_MESSAGES.FORBIDDEN);
      }

      await Project.findByIdAndDelete(projectId);
      return true;
    } catch (error) {
      throw error;
    }
  }

  static async addCollaborator(projectId, userId, collaboratorEmail) {
    try {
      const project = await Project.findById(projectId);

      if (!project) {
        throw new Error(ERROR_MESSAGES.PROJECT_NOT_FOUND);
      }

      // Check if user is owner
      if (project.owner.toString() !== userId) {
        throw new Error(ERROR_MESSAGES.FORBIDDEN);
      }

      // Check if collaborator already exists
      const existingCollaborator = project.collaborators.find(
        c => c.user.email === collaboratorEmail
      );

      if (existingCollaborator) {
        throw new Error('User is already a collaborator');
      }

      // Find collaborator user
      const User = (await import('../models/User.js')).default;
      const collaboratorUser = await User.findOne({ email: collaboratorEmail });

      if (!collaboratorUser) {
        throw new Error('User not found');
      }

      // Add collaborator
      project.collaborators.push({
        user: collaboratorUser._id,
        role: 'collaborator',
        permissions: ['read', 'write']
      });

      await project.save();

      const updatedProject = await Project.findById(projectId)
        .populate('owner', 'name email')
        .populate('collaborators.user', 'name email');

      return updatedProject;
    } catch (error) {
      throw error;
    }
  }

  static async removeCollaborator(projectId, userId, collaboratorId) {
    try {
      const project = await Project.findById(projectId);

      if (!project) {
        throw new Error(ERROR_MESSAGES.PROJECT_NOT_FOUND);
      }

      // Check if user is owner
      if (project.owner.toString() !== userId) {
        throw new Error(ERROR_MESSAGES.FORBIDDEN);
      }

      // Remove collaborator
      project.collaborators = project.collaborators.filter(
        c => c.user.toString() !== collaboratorId
      );

      await project.save();

      const updatedProject = await Project.findById(projectId)
        .populate('owner', 'name email')
        .populate('collaborators.user', 'name email');

      return updatedProject;
    } catch (error) {
      throw error;
    }
  }

  static async addWidget(projectId, userId, widgetData) {
    try {
      const project = await Project.findById(projectId);

      if (!project) {
        throw new Error(ERROR_MESSAGES.PROJECT_NOT_FOUND);
      }

      // Check if user has access
      const hasAccess = project.owner.toString() === userId ||
                       project.collaborators.some(c => c.user.toString() === userId);

      if (!hasAccess) {
        throw new Error(ERROR_MESSAGES.FORBIDDEN);
      }

      project.widgets.push(widgetData);
      await project.save();

      return project;
    } catch (error) {
      throw error;
    }
  }

  static async updateWidget(projectId, userId, widgetId, widgetData) {
    try {
      const project = await Project.findById(projectId);

      if (!project) {
        throw new Error(ERROR_MESSAGES.PROJECT_NOT_FOUND);
      }

      // Check if user has access
      const hasAccess = project.owner.toString() === userId ||
                       project.collaborators.some(c => c.user.toString() === userId);

      if (!hasAccess) {
        throw new Error(ERROR_MESSAGES.FORBIDDEN);
      }

      const widgetIndex = project.widgets.findIndex(w => w.id === widgetId);
      if (widgetIndex === -1) {
        throw new Error(ERROR_MESSAGES.WIDGET_NOT_FOUND);
      }

      project.widgets[widgetIndex] = { ...project.widgets[widgetIndex], ...widgetData };
      await project.save();

      return project;
    } catch (error) {
      throw error;
    }
  }

  static async deleteWidget(projectId, userId, widgetId) {
    try {
      const project = await Project.findById(projectId);

      if (!project) {
        throw new Error(ERROR_MESSAGES.PROJECT_NOT_FOUND);
      }

      // Check if user has access
      const hasAccess = project.owner.toString() === userId ||
                       project.collaborators.some(c => c.user.toString() === userId);

      if (!hasAccess) {
        throw new Error(ERROR_MESSAGES.FORBIDDEN);
      }

      project.widgets = project.widgets.filter(w => w.id !== widgetId);
      await project.save();

      return project;
    } catch (error) {
      throw error;
    }
  }
}

export default ProjectService;
