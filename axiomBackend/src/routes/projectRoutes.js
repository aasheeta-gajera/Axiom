// const express = require('express');
// const router = express.Router();
// const Project = require('../models/Project');
// const auth = require('../middleware/auth');

import { Router } from 'express';
import { Project } from '../models/Project.js';
import { auth } from '../middleware/auth.js';
const router = Router();

// Create project
router.post('/', auth, async (req, res) => {
  try {
    const project = new Project({
      ...req.body,
      owner: req.userId,
      widgets: [],
      screens: [{
        id: 'screen_1',
        name: 'Home',
        route: '/',
        widgets: []
      }]
    });
    await project.save();
    res.status(201).json(project);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all projects for user
router.get('/', auth, async (req, res) => {
  try {
    console.log('🔍 Loading projects for user:', req.userId);
    const projects = await Project.find({ owner: req.userId });
    console.log('📊 Found projects:', projects.length);
    res.json(projects);
  } catch (error) {
    console.error('❌ Error loading projects:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get single project
// router.get('/:id', auth, async (req, res) => {
//   try {
//     const project = await Project.findById(req.params.id);
//     if (!project) {
//       return res.status(404).json({ error: 'Project not found' });
//     }
//     res.json(project);
//   } catch (error) {
//     res.status(500).json({ error: error.message });
//   }
// });

// Update project
router.put('/:id', auth, async (req, res) => {
  try {
    const project = await Project.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );
    res.json(project);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete project
router.delete('/:id', auth, async (req, res) => {
  try {
    await Project.findByIdAndDelete(req.params.id);
    res.json({ message: 'Project deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update widgets in screen
router.put('/:id/screens/:screenId/widgets', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.id);
    const screen = project.screens.find(s => s.id === req.params.screenId);
    if (screen) {
      screen.widgets = req.body.widgets;
      await project.save();
      res.json(project);
    } else {
      res.status(404).json({ error: 'Screen not found' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// module.exports = router;
export const projectRoutes = router;