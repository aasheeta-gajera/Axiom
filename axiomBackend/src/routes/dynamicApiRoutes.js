// Dynamic API Execution Routes - Handles all form submissions
import { Router } from 'express';
import mongoose from 'mongoose';

const router = Router();

// POST to dynamic collection (Registration, Login, etc.)
router.post('/dynamic/:collection', async (req, res) => {
  try {
    const { collection } = req.params;
    const { method, data, purpose } = req.body;
    
    console.log('🔥 Creating model for collection:', collection);
    console.log('📝 Data received:', data);
    
    // Create dynamic model for collection with explicit database
    const DynamicModel = mongoose.models[collection] || 
      mongoose.model(collection, new mongoose.Schema({}, { 
        strict: false, 
        collection: collection,
        timestamps: true 
      }), 'axiom'); // Explicitly use 'axiom' database
    
    if (purpose === 'register') {
      // Handle user registration
      const existingUser = await DynamicModel.findOne({ email: data.email });
      if (existingUser) {
        return res.status(400).json({ error: 'User already exists' });
      }
    }
    
    // Create new record
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

// GET from dynamic collection
router.get('/dynamic/:collection', async (req, res) => {
  try {
    const { collection } = req.params;
    console.log('📖 Getting data from collection:', collection);
    
    const DynamicModel = mongoose.models[collection] || 
      mongoose.model(collection, new mongoose.Schema({}, { 
        strict: false, 
        collection: collection,
        timestamps: true 
      }), 'axiom'); // Explicitly use 'axiom' database
    
    const items = await DynamicModel.find({});
    console.log('📊 Found', items.length, 'items');
    res.json({ success: true, data: items });
    
  } catch (error) {
    console.error('Get Data Error:', error);
    res.status(500).json({ error: error.message });
  }
});

export default router;
