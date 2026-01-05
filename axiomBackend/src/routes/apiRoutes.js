
import { Router } from 'express';
import {Project} from '../models/Project.js';
import {auth} from '../middleware/auth.js';
import express from 'express';
import mongoose from 'mongoose';
const router = Router();

// Add API endpoint to project (Phase 2)
// In apiRoutes.js, update the endpoint creation
router.post('/:projectId/endpoints', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    
    if (!project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    // Validate fields if they exist
    const fields = (req.body.fields || []).map(field => ({
      name: field.name,
      type: field.type || 'String',
      required: field.required || false,
      unique: field.unique || false,
      defaultValue: field.defaultValue || null,
      validation: field.validation || null
    }));

    const newEndpoint = {
      id: `api_${Date.now()}`,
      name: req.body.name,
      method: req.body.method,
      path: req.body.path,
      description: req.body.description,
      purpose: req.body.purpose,
      auth: req.body.auth || false,
      collectionName: req.body.collectionName, // Changed from collection to collectionName
      fields: fields,
      createCollection: req.body.createCollection || false,
      requestExample: req.body.requestExample,
      responseExample: req.body.responseExample,
      controller: req.body.controller,
      model: req.body.model
    };

    // Rest of the code remains the same...
    project.apis.push(newEndpoint);
    await project.save();

    res.status(201).json(newEndpoint);
  } catch (error) {
    console.error('Error creating API endpoint:', error);
    res.status(500).json({ 
      error: 'Failed to create API endpoint',
      details: error.message 
    });
  }
});

// Get all API endpoints for project
router.get('/:projectId/endpoints', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    res.json(project.apis);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update API endpoint
router.put('/:projectId/endpoints/:endpointId', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    const endpointIndex = project.apis.findIndex(api => api.id === req.params.endpointId);
    if (endpointIndex === -1) {
      return res.status(404).json({ error: 'Endpoint not found' });
    }
    Object.assign(project.apis[endpointIndex], req.body);
    await project.save();

    res.json(project.apis[endpointIndex]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete API endpoint
router.delete('/:projectId/endpoints/:endpointId', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    project.apis = project.apis.filter(api => api.id !== req.params.endpointId);
    await project.save();

    res.json({ message: 'Endpoint deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Generate CRUD APIs for a model
router.post('/:projectId/generate-crud', auth, async (req, res) => {
  try {
    const { modelName } = req.body;
    const project = await Project.findById(req.params.projectId);

    const crudEndpoints = [
      { method: 'GET', path: `/${modelName.toLowerCase()}`, description: `Get all ${modelName}` },
      { method: 'GET', path: `/${modelName.toLowerCase()}/:id`, description: `Get ${modelName} by ID` },
      { method: 'POST', path: `/${modelName.toLowerCase()}`, description: `Create ${modelName}` },
      { method: 'PUT', path: `/${modelName.toLowerCase()}/:id`, description: `Update ${modelName}` },
      { method: 'DELETE', path: `/${modelName.toLowerCase()}/:id`, description: `Delete ${modelName}` }
    ];

    crudEndpoints.forEach(endpoint => {
      project.apis.push({
        id: `api_${Date.now()}_${Math.random()}`,
        ...endpoint,
        model: modelName
      });
    });

    await project.save();
    res.json({ message: 'CRUD endpoints generated', endpoints: crudEndpoints });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// module.exports = router;

export const apiRoutes = router;