// Enhanced API Routes with Dynamic Collection Support
import { Router } from 'express';
import { Project } from '../models/Project.js';
import { auth } from '../middleware/auth.js';
import mongoose from 'mongoose';

const router = Router();

// Create or Update API with full configuration
router.post('/:projectId/apis', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    if (!project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    const {
      id,
      name,
      method,
      path,
      description,
      purpose,
      auth: requiresAuth,
      collection,
      fields,
      createCollection,
      requestExample,
      responseExample
    } = req.body;

    // Check if API already exists
    const existingIndex = project.apis.findIndex(api => api.id === id);

    const apiEndpoint = {
      id: id || `api_${Date.now()}`,
      name,
      method,
      path,
      description,
      purpose,
      auth: requiresAuth || false,
      collection,
      fields,
      createCollection,
      requestExample,
      responseExample
    };

    if (existingIndex !== -1) {
      // Update existing API
      project.apis[existingIndex] = apiEndpoint;
    } else {
      // Add new API
      project.apis.push(apiEndpoint);
    }

    // If creating new collection, add to project collections
    if (createCollection && !project.collections.includes(collection)) {
      project.collections.push(collection);
      
      // Create dynamic Mongoose model
      await createDynamicModel(collection, fields);
    }

    await project.save();

    // Generate backend code for this API
    const backendCode = generateBackendCode(apiEndpoint, fields);

    res.status(201).json({
      api: apiEndpoint,
      backendCode,
      message: 'API created successfully'
    });
  } catch (error) {
    console.error('API creation error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get all APIs for a project
router.get('/:projectId/apis', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    if (!project) {
      return res.status(404).json({ error: 'Project not found' });
    }

    res.json({
      apis: project.apis,
      collections: project.collections
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete API
router.delete('/:projectId/apis/:apiId', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    project.apis = project.apis.filter(api => api.id !== req.params.apiId);
    await project.save();

    res.json({ message: 'API deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get available collections
router.get('/:projectId/collections', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    res.json({ collections: project.collections || [] });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Test API endpoint
router.post('/:projectId/apis/:apiId/test', auth, async (req, res) => {
  try {
    const project = await Project.findById(req.params.projectId);
    const api = project.apis.find(a => a.id === req.params.apiId);
    
    if (!api) {
      return res.status(404).json({ error: 'API not found' });
    }

    // Simulate API call
    const result = await testAPICall(api, req.body);
    
    res.json({
      success: true,
      api: api.name,
      request: req.body,
      response: result
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Helper: Create dynamic Mongoose model
async function createDynamicModel(collectionName, fields) {
  // Check if model already exists
  if (mongoose.models[collectionName]) {
    return mongoose.models[collectionName];
  }

  const schemaDefinition = {};
  
  fields.forEach(field => {
    let type;
    switch (field.type) {
      case 'String':
        type = String;
        break;
      case 'Number':
        type = Number;
        break;
      case 'Boolean':
        type = Boolean;
        break;
      case 'Date':
        type = Date;
        break;
      case 'Array':
        type = Array;
        break;
      case 'ObjectId':
        type = mongoose.Schema.Types.ObjectId;
        break;
      default:
        type = String;
    }

    schemaDefinition[field.name] = {
      type,
      required: field.required || false,
      unique: field.unique || false,
      default: field.defaultValue
    };

    // Add validation for email
    if (field.validation === 'email') {
      schemaDefinition[field.name].match = [
        /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
        'Please enter a valid email'
      ];
    }
  });

  const schema = new mongoose.Schema(schemaDefinition, { timestamps: true });
  return mongoose.model(collectionName, schema);
}

// Helper: Test API call
async function testAPICall(api, data) {
  try {
    const Model = mongoose.models[api.collection];
    
    if (!Model) {
      throw new Error(`Collection ${api.collection} not found`);
    }

    switch (api.method) {
      case 'POST':
        const newDoc = new Model(data);
        const saved = await newDoc.save();
        return { _id: saved._id, ...data };

      case 'GET':
        if (data._id) {
          return await Model.findById(data._id);
        }
        return await Model.find(data).limit(10);

      case 'PUT':
        if (!data._id) {
          throw new Error('ID required for update');
        }
        const updated = await Model.findByIdAndUpdate(data._id, data, { new: true });
        return updated;

      case 'DELETE':
        if (!data._id) {
          throw new Error('ID required for delete');
        }
        await Model.findByIdAndDelete(data._id);
        return { message: 'Deleted successfully' };

      default:
        throw new Error(`Method ${api.method} not supported`);
    }
  } catch (error) {
    throw error;
  }
}

// Helper: Generate backend code
function generateBackendCode(api, fields) {
  const modelName = api.collection.charAt(0).toUpperCase() + api.collection.slice(1);
  
  let code = `// ${api.name} - ${api.description}\n`;
  code += `router.${api.method.toLowerCase()}('${api.path}', `;
  
  if (api.auth) {
    code += 'authMiddleware, ';
  }
  
  code += `async (req, res) => {\n`;
  code += `  try {\n`;

  switch (api.purpose) {
    case 'login':
      code += generateLoginCode(modelName, fields);
      break;
    case 'register':
      code += generateRegisterCode(modelName, fields);
      break;
    case 'create':
      code += generateCreateCode(modelName, fields);
      break;
    case 'read':
      code += generateReadCode(modelName);
      break;
    case 'update':
      code += generateUpdateCode(modelName, fields);
      break;
    case 'delete':
      code += generateDeleteCode(modelName);
      break;
    case 'list':
      code += generateListCode(modelName);
      break;
  }

  code += `  } catch (error) {\n`;
  code += `    res.status(500).json({ error: error.message });\n`;
  code += `  }\n`;
  code += `});\n\n`;

  return code;
}

function generateLoginCode(modelName, fields) {
  return `    const { email, password } = req.body;
    
    // Find user by email
    const user = await ${modelName}.findOne({ email });
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Verify password (assuming bcrypt)
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, { expiresIn: '7d' });

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        email: user.email,
        name: user.name
      }
    });
`;
}

function generateRegisterCode(modelName, fields) {
  const fieldNames = fields.map(f => f.name).join(', ');
  return `    const { ${fieldNames} } = req.body;

    // Check if user already exists
    const existingUser = await ${modelName}.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ error: 'User already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user
    const user = new ${modelName}({
      ${fields.map(f => f.name === 'password' ? 'password: hashedPassword' : f.name).join(',\n      ')}
    });

    await user.save();

    // Generate token
    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, { expiresIn: '7d' });

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: {
        id: user._id,
        ${fields.filter(f => f.name !== 'password').map(f => `${f.name}: user.${f.name}`).join(',\n        ')}
      }
    });
`;
}

function generateCreateCode(modelName, fields) {
  const fieldNames = fields.map(f => f.name).join(', ');
  return `    const { ${fieldNames} } = req.body;

    const newItem = new ${modelName}({
      ${fields.map(f => f.name).join(',\n      ')}
    });

    await newItem.save();

    res.status(201).json({
      message: 'Created successfully',
      data: newItem
    });
`;
}

function generateReadCode(modelName) {
  return `    const { id } = req.params;

    if (id) {
      const item = await ${modelName}.findById(id);
      if (!item) {
        return res.status(404).json({ error: 'Not found' });
      }
      res.json({ data: item });
    } else {
      const items = await ${modelName}.find();
      res.json({ data: items });
    }
`;
}

function generateUpdateCode(modelName, fields) {
  return `    const { id } = req.params;
    const updateData = req.body;

    const updated = await ${modelName}.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!updated) {
      return res.status(404).json({ error: 'Not found' });
    }

    res.json({
      message: 'Updated successfully',
      data: updated
    });
`;
}

function generateDeleteCode(modelName) {
  return `    const { id } = req.params;

    const deleted = await ${modelName}.findByIdAndDelete(id);

    if (!deleted) {
      return res.status(404).json({ error: 'Not found' });
    }

    res.json({ message: 'Deleted successfully' });
`;
}

function generateListCode(modelName) {
  return `    const { page = 1, limit = 10, search } = req.query;
    const skip = (page - 1) * limit;

    let query = {};
    if (search) {
      // Add search logic based on your fields
      query = { $text: { $search: search } };
    }

    const items = await ${modelName}
      .find(query)
      .skip(skip)
      .limit(parseInt(limit))
      .sort({ createdAt: -1 });

    const total = await ${modelName}.countDocuments(query);

    res.json({
      data: items,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
`;
}

export const enhancedApiRoutes = router;