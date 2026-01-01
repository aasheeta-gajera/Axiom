import { Router } from 'express';
import jwt from 'jsonwebtoken';
import mongoose from 'mongoose';

const router = Router();

// Get dynamic User model
const getDynamicUserModel = () => {
  return mongoose.models.users || 
    mongoose.model('users', new mongoose.Schema({}, { 
      strict: false, 
      collection: 'users',
      timestamps: true 
    }), 'axiom');
};

// Register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;

    const User = getDynamicUserModel();
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ error: 'Email already exists' });
    }

    const user = new User({ name, email, password });
    await user.save();

    console.log('New user registered:', user);
    const token = jwt.sign(
      { userId: user._id }, 
      process.env.JWT_SECRET || 'axiomjwtaxiomjwtaxiomjwtaxiomjwt', 
      { expiresIn: '7d' }
    );

    res.status(201).json({
      message: 'User created successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    console.log(' Login attempt for:', email);

    const User = getDynamicUserModel();
    const user = await User.findOne({ email });
    if (!user) {
      console.log(' User not found');
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    console.log(' Found user:', user.email);
    console.log(' Stored password:', user.password);
    console.log(' Provided password:', password);

    // Simple password comparison (for testing)
    const isMatch = user.password === password;
    console.log(' Password match:', isMatch);

    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { userId: user._id }, 
      process.env.JWT_SECRET || 'axiomjwtaxiomjwtaxiomjwtaxiomjwt', 
      { expiresIn: '7d' }
    );

    console.log(' Login successful');
    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email
      }
    });
  } catch (error) {
    console.error(' Login error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get current user
router.get('/me', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId).select('-password');
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
});

export const authRoutes = router;