import { Router } from 'express';
import ProjectController from '../controllers/project_controller.js';
import auth from '../middleware/auth.js';
import ErrorHandler from '../middleware/error_handler.js';

const router = Router();

// All routes are protected and require authentication
router.use(auth);

// Project CRUD operations
router.post('/', ErrorHandler.asyncWrapper(ProjectController.createProject));
router.get('/', ErrorHandler.asyncWrapper(ProjectController.getProjects));
router.get('/:projectId', ErrorHandler.asyncWrapper(ProjectController.getProject));
router.put('/:projectId', ErrorHandler.asyncWrapper(ProjectController.updateProject));
router.delete('/:projectId', ErrorHandler.asyncWrapper(ProjectController.deleteProject));

// Collaborator management
router.post('/:projectId/collaborators', ErrorHandler.asyncWrapper(ProjectController.addCollaborator));
router.delete('/:projectId/collaborators/:collaboratorId', ErrorHandler.asyncWrapper(ProjectController.removeCollaborator));

// Widget management
router.post('/:projectId/widgets', ErrorHandler.asyncWrapper(ProjectController.addWidget));
router.put('/:projectId/widgets/:widgetId', ErrorHandler.asyncWrapper(ProjectController.updateWidget));
router.delete('/:projectId/widgets/:widgetId', ErrorHandler.asyncWrapper(ProjectController.deleteWidget));

export default router;
