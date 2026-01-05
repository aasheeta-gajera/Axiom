// Dynamic API Execution Routes - Handles all form submissions and custom API endpoints
import { Router } from 'express';
import mongoose from 'mongoose';
import {Project} from '../models/Project.js';
import jwt from 'jsonwebtoken';

const router = Router();

// Helper function to get or create a dynamic model
function getDynamicModel(collectionName) {
  // Validate collection name
  if (!collectionName || typeof collectionName !== 'string') {
    throw new Error('Collection name must be a string');
  }
  
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
  
  return mongoose.model(collectionName, schema);
}

function normalizeApiPath(value) {
  if (!value || typeof value !== 'string') return '/';
  let p = value.trim();
  if (!p.startsWith('/')) p = `/${p}`;
  if (p.length > 1 && p.endsWith('/')) p = p.slice(0, -1);
  if (p.startsWith('/api/')) p = p.slice(4);
  if (p === '/api') p = '/';
  return p;
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
    const path = req.path; // Keep the leading slash for matching
    const method = req.method.toUpperCase();
    const normalizedRequestPath = normalizeApiPath(path);
    const candidatePaths = Array.from(
      new Set([
        path,
        normalizedRequestPath,
        normalizedRequestPath.replace(/^\//, ''),
        `/api${normalizedRequestPath}`,
        `api${normalizedRequestPath}`
      ])
    );
    
    console.log(`🔥 Dynamic API Request: ${method} ${path}`);
    console.log('📝 Request body:', req.body);
    console.log('🔍 Full URL:', req.originalUrl);
    console.log('🔍 Base URL:', req.baseUrl);
    
    // Find project that contains this API endpoint
    const projects = await Project.find({
      'apis.method': method,
      'apis.path': { $in: candidatePaths }
    });
    
    console.log(`🔍 Found ${projects.length} projects with matching API`);
    
    // Debug: Show all available APIs in all projects
    const allProjects = await Project.find({});
    console.log('📋 All available APIs:');
    allProjects.forEach(proj => {
      proj.apis.forEach(api => {
        console.log(`  - ${api.method} ${api.path} (Project: ${proj.name})`);
      });
    });
    
    if (projects.length === 0) {
      console.log(`❌ No matching API found for ${method} ${path}`);
      return next(); // Pass to next route handler
    }
    
    // Find the specific API configuration
    let apiConfig = null;
    let project = null;
    
    for (const proj of projects) {
      const api = proj.apis.find(api => {
        if (api.method !== method) return false;
        return normalizeApiPath(api.path) === normalizedRequestPath;
      });
      if (api) {
        apiConfig = api;
        project = proj;
        break;
      }
    }
    
    if (!apiConfig) {
      console.log(`❌ API config not found for ${method} ${path}`);
      return next(); // Pass to next route handler
    }
    
    console.log(`📋 Found API config: ${apiConfig.name} (${apiConfig.purpose})`);
    console.log('🔍 API Config details:', JSON.stringify(apiConfig, null, 2));
    console.log('🔍 Collection name:', apiConfig.collectionName);
    
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
    
    // Validate collection name before creating model
    if (!apiConfig.collectionName) {
      console.error('❌ Collection name is missing in API config');
      return res.status(500).json({ 
        error: 'Configuration error', 
        message: 'Collection name not specified in API configuration' 
      });
    }
    
    // Get the dynamic model for the collection
    const DynamicModel = getDynamicModel(apiConfig.collectionName);
    
    // Handle different HTTP methods
    let result;
    switch (method) {
      case 'GET':
        if (req.params.id || path.includes('/') && path.split('/').length > 2) {
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
         const postData = req.body.data || req.body;
        const validationErrors = validateRequestData(postData, apiConfig.fields || [], apiConfig.purpose);
        if (validationErrors.length > 0) {
          return res.status(400).json({ 
            error: 'Validation failed', 
            details: validationErrors 
          });
        }
        
        // Handle special purposes
        if (apiConfig.purpose === 'register') {
          const existingUser = await DynamicModel.findOne({ email: postData.email });
          if (existingUser) {
            return res.status(400).json({ error: 'User already exists' });
          }
        }
        
        if (apiConfig.purpose === 'login') {
          const user = await DynamicModel.findOne({ email: postData.email });
          if (!user || user.password !== postData.password) { // Note: In production, use proper password hashing
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
        result = new DynamicModel(postData);
        await result.save();
        break;
        
      case 'PUT':
        const updateId = req.params.id || req.body.id;
        if (!updateId) {
          return res.status(400).json({ error: 'ID required for update' });
        }
        
         const updateData = req.body.data || req.body;
        result = await DynamicModel.findByIdAndUpdate(
          updateId, 
          updateData, 
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
          message: 'Item deleted successfully',
           data: result
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
   if (error.name === 'ValidationError') {
      return res.status(400).json({ 
        error: 'Validation error',
        details: Object.values(error.errors).map(e => e.message)
      });
    }
    
    if (error.name === 'CastError') {
      return res.status(400).json({ 
        error: 'Invalid ID format'
      });
    }
    
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message,
      type: error.name
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
      if (method === 'POST') return 'Data created successfully';
      if (method === 'GET') return 'Data retrieved successfully';
      if (method === 'PUT') return 'Data updated successfully';
      if (method === 'DELETE') return 'Data deleted successfully';
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
