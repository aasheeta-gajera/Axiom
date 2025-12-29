// const express = require('express');
// const router = express.Router();
// const Project = require('../models/Project');
// const auth = require('../middleware/auth');

import { Router } from 'express';
import { Project } from '../models/Project.js';
import {auth} from '../middleware/auth.js';
import express from 'express';
const router = Router();

// Add data model to project (Phase 2)
router.post('/:projectId/models', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    
    const newModel = {
      id: `model_${Date.now()}`,
      name: req.body.name,
      fields: req.body.fields,
      timestamps: req.body.timestamps !== false
    };

    project.dataModels.push(newModel);
    await project.save();

    res.status(201).json(newModel);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all data models
router.get('/:projectId/models', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    res.json(project.dataModels);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update data model
router.put('/:projectId/models/:modelId', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    const modelIndex = project.dataModels.findIndex(m => m.id === req.params.modelId);
    
    if (modelIndex === -1) {
      return res.status(404).json({ error: 'Model not found' });
    }

    project.dataModels[modelIndex] = {
      ...project.dataModels[modelIndex],
      ...req.body
    };
    
    await project.save();
    res.json(project.dataModels[modelIndex]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete data model
router.delete('/:projectId/models/:modelId', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    project.dataModels = project.dataModels.filter(m => m.id !== req.params.modelId);
    await project.save();

    res.json({ message: 'Model deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// module.exports = router;
export const componentRoutes = router;