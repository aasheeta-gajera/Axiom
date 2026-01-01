// Dynamic API Execution Routes - Handles all form submissions and custom API endpoints
import { Router } from 'express';
import mongoose from 'mongoose';
import {Project} from '../models/Project.js';
import jwt from 'jsonwebtoken';

const router = Router();

// Helper function to get or create a dynamic model
function getDynamicModel(collectionName) {
  // Check if model already exists
  if (mongoose.models[collectionName]) {
    return mongoose.models[collectionName];
  }
  
  // Create new model with flexible schema
  const schema = new mongoose.Schema({}, { 
    strict: false, 
    collection: collectionName,
    timestamps: true 
  });
  
  return mongoose.model(collectionName, schema, 'axiom');
}

// Helper function to validate request data against API fields
function validateRequestData(data, fields, purpose) {
  const errors = [];
  
  if (purpose === 'register' && data.email) {
    // Basic email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(data.email)) {
      errors.push('Invalid email format');
    }
  }
  
  // Check required fields
  fields.forEach(field => {
    if (field.required && !data[field.name]) {
      errors.push(`${field.name} is required`);
    }
  });
  
  return errors;
}

// Main dynamic API handler - processes requests based on stored API configurations
router.use(async (req, res, next) => {
  try {
    const path = req.path.replace(/^\//, ''); // Remove leading slash
    const method = req.method.toUpperCase();
    
    console.log(`🔥 Dynamic API Request: ${method} /${path}`);
    console.log('📝 Request body:', req.body);
    
    // Find project that contains this API endpoint
    const projects = await Project.find({
      'apis.path': '/' + path,
      'apis.method': method
    });
    
    if (projects.length === 0) {
      return next(); // Pass to next route handler
    }
    
    // Find the specific API configuration
    let apiConfig = null;
    let project = null;
    
    for (const proj of projects) {
      const api = proj.apis.find(api => api.path === '/' + path && api.method === method);
      if (api) {
        apiConfig = api;
        project = proj;
        break;
      }
    }
    
    if (!apiConfig) {
      return next(); // Pass to next route handler
    }
    
    console.log(`📋 Found API config: ${apiConfig.name} (${apiConfig.purpose})`);
    
    // Check authentication if required
    if (apiConfig.auth) {
      const token = req.headers.authorization?.replace('Bearer ', '');
      if (!token) {
        return res.status(401).json({ error: 'Authentication required' });
      }
      
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;
      } catch (authError) {
        return res.status(401).json({ error: 'Invalid or expired token' });
      }
    }
    
    // Get the dynamic model for the collection
    const DynamicModel = getDynamicModel(apiConfig.collection);
    
    // Handle different HTTP methods
    let result;
    switch (method) {
      case 'GET':
        if (req.params.id || path.includes('/')) {
          // Get single item by ID (for paths like /users/:id)
          const id = req.params.id || path.split('/').pop();
          result = await DynamicModel.findById(id);
          if (!result) {
            return res.status(404).json({ error: 'Item not found' });
          }
        } else {
          // Get all items
          result = await DynamicModel.find({});
        }
        break;
        
      case 'POST':
        // Validate request data
        const validationErrors = validateRequestData(req.body, apiConfig.fields || [], apiConfig.purpose);
        if (validationErrors.length > 0) {
          return res.status(400).json({ 
            error: 'Validation failed', 
            details: validationErrors 
          });
        }
        
        // Handle special purposes
        if (apiConfig.purpose === 'register') {
          const existingUser = await DynamicModel.findOne({ email: req.body.email });
          if (existingUser) {
            return res.status(400).json({ error: 'User already exists' });
          }
        }
        
        if (apiConfig.purpose === 'login') {
          const user = await DynamicModel.findOne({ email: req.body.email });
          if (!user || user.password !== req.body.password) { // Note: In production, use proper password hashing
            return res.status(401).json({ error: 'Invalid credentials' });
          }
          
          const token = jwt.sign(
            { userId: user._id }, 
            process.env.JWT_SECRET || 'axiomjwtaxiomjwtaxiomjwtaxiomjwt', 
            { expiresIn: '7d' }
          );
          
          return res.json({
            success: true,
            message: 'Login successful',
            token,
            user: {
              id: user._id,
              email: user.email,
              name: user.name
            }
          });
        }
        
        // Create new item
        result = new DynamicModel(req.body);
        await result.save();
        break;
        
      case 'PUT':
        const updateId = req.params.id || req.body.id;
        if (!updateId) {
          return res.status(400).json({ error: 'ID required for update' });
        }
        
        result = await DynamicModel.findByIdAndUpdate(
          updateId, 
          req.body, 
          { new: true, runValidators: true }
        );
        
        if (!result) {
          return res.status(404).json({ error: 'Item not found' });
        }
        break;
        
      case 'DELETE':
        const deleteId = req.params.id || req.body.id;
        if (!deleteId) {
          return res.status(400).json({ error: 'ID required for delete' });
        }
        
        result = await DynamicModel.findByIdAndDelete(deleteId);
        if (!result) {
          return res.status(404).json({ error: 'Item not found' });
        }
        
        return res.json({
          success: true,
          message: 'Item deleted successfully'
        });
        
      default:
        return res.status(405).json({ error: 'Method not allowed' });
    }
    
    console.log(`✅ ${method} /${path} processed successfully`);
    
    // Return success response
    const response = {
      success: true,
      message: getSuccessMessage(apiConfig.purpose, method),
      data: result
    };
    
    res.status(method === 'POST' ? 201 : 200).json(response);
    
  } catch (error) {
    console.error('❌ Dynamic API Error:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message 
    });
  }
});

// Helper function to get appropriate success messages
function getSuccessMessage(purpose, method) {
  switch (purpose) {
    case 'register':
      return 'User registered successfully';
    case 'login':
      return 'Login successful';
    case 'create':
      return 'Data created successfully';
    case 'read':
      return 'Data retrieved successfully';
    case 'update':
      return 'Data updated successfully';
    case 'delete':
      return 'Data deleted successfully';
    case 'list':
      return 'Data listed successfully';
    default:
      return 'Operation successful';
  }
}

// Legacy routes for backward compatibility
router.post('/dynamic/:collection', async (req, res) => {
  try {
    const { collection } = req.params;
    const { method, data, purpose } = req.body;
    
    console.log('🔥 Creating model for collection:', collection);
    console.log('📝 Data received:', data);
    
    const DynamicModel = getDynamicModel(collection);
    
    if (purpose === 'register') {
      const existingUser = await DynamicModel.findOne({ email: data.email });
      if (existingUser) {
        return res.status(400).json({ error: 'User already exists' });
      }
    }
    
    const newItem = new DynamicModel({
      ...data,
      createdAt: new Date(),
      updatedAt: new Date()
    });
    
    console.log('💾 Saving item:', newItem);
    await newItem.save();
    console.log('✅ Item saved successfully!');
    
    res.status(201).json({ 
      success: true, 
      message: purpose === 'register' ? 'User registered successfully' : 'Data saved successfully',
      data: newItem 
    });
    
  } catch (error) {
    console.error('Dynamic API Error:', error);
    res.status(500).json({ error: error.message });
  }
});

router.get('/dynamic/:collection', async (req, res) => {
  try {
    const { collection } = req.params;
    console.log('📖 Getting data from collection:', collection);
    
    const DynamicModel = getDynamicModel(collection);
    const items = await DynamicModel.find({});
    console.log('📊 Found', items.length, 'items');
    res.json({ success: true, data: items });
    
  } catch (error) {
    console.error('Get Data Error:', error);
    res.status(500).json({ error: error.message });
  }
});

export default router;
