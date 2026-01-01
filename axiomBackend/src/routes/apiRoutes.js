// const express = require('express');
// const router = express.Router();
// const Project = require('../models/Project');
// const auth = require('../middleware/auth');

import { Router } from 'express';
import {Project} from '../models/Project.js';
import {auth} from '../middleware/auth.js';
import express from 'express';
import mongoose from 'mongoose';
const router = Router();

// Add API endpoint to project (Phase 2)
router.post('/:projectId/endpoints', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    
    if (!project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    const newEndpoint = {
      id: `api_${Date.now()}`,
      name: req.body.name,
      method: req.body.method,
      path: req.body.path,
      description: req.body.description,
      purpose: req.body.purpose,
      auth: req.body.auth || false,
      collection: req.body.collection,
      fields: req.body.fields || [],
      createCollection: req.body.createCollection || false,
      requestExample: req.body.requestExample,
      responseExample: req.body.responseExample,
      controller: req.body.controller,
      model: req.body.model
    };

    // Create collection if requested
    if (newEndpoint.createCollection && newEndpoint.collection) {
      try {
        // Check if collection already exists
        const collections = await mongoose.connection.db.listCollections().toArray();
        const collectionExists = collections.some(col => col.name === newEndpoint.collection);
        
        if (!collectionExists) {
          // Create the collection by inserting a dummy document and then removing it
          const DynamicModel = mongoose.model(newEndpoint.collection, new mongoose.Schema({}, { 
            strict: false, 
            collection: newEndpoint.collection,
            timestamps: true 
          }), 'axiom');
          
          // Create a dummy document to initialize the collection
          await DynamicModel.create({ _init: true });
          await DynamicModel.deleteMany({ _init: true });
          
          console.log(`✅ Created collection: ${newEndpoint.collection}`);
        }
      } catch (collectionError) {
        console.error('❌ Error creating collection:', collectionError);
        return res.status(500).json({ error: 'Failed to create collection: ' + collectionError.message });
      }
    }

    project.apis.push(newEndpoint);
    await project.save();

    console.log(`✅ Created API endpoint: ${newEndpoint.method} ${newEndpoint.path}`);
    res.status(201).json(newEndpoint);
  } catch (error) {
    console.error('❌ Error creating API endpoint:', error);
    res.status(500).json({ error: error.message });
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

    res.json(endpoint);
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