// const mongoose = require('mongoose');
import mongoose from 'mongoose';

const widgetSchema = new mongoose.Schema({
  id: { type: String, required: true },
  type: { 
    type: String, 
    required: true,
    enum: ['Container', 'Text', 'Button', 'Image', 'Card', 'Row', 'Column', 'ListView', 'TextField', 'AppBar', 'Scaffold']
  },
  properties: {
    text: String,
    color: String,
    backgroundColor: String,
    padding: Object,
    margin: Object,
    width: Number,
    height: Number,
    fontSize: Number,
    fontWeight: String,
    alignment: String,
    mainAxisAlignment: String,
    crossAxisAlignment: String,
    borderRadius: Number,
    image: String,
    onTap: String
  },
children: [{
    type: Object,
    default: []
  }],  position: {
    x: Number,
    y: Number
  },
  parent: String
}, { _id: false });

const apiEndpointSchema = new mongoose.Schema({
  id: { type: String, required: true },
  name: { type: String, required: true },
  method: { 
    type: String, 
    enum: ['GET', 'POST', 'PUT', 'DELETE'],
    required: true 
  },
  path: { type: String, required: true },
  description: String,
  purpose: String,
  auth: { type: Boolean, default: false },
  collection: String,
  fields: [{
    name: String,
    type: String,
    required: Boolean,
    unique: Boolean,
    default: mongoose.Schema.Types.Mixed,
    validation: String
  }],
  createCollection: { type: Boolean, default: false },
  requestExample: String,
  responseExample: String,
  controller: String,
  model: String
}, { _id: false });

const dataModelSchema = new mongoose.Schema({
  id: { type: String, required: true },
  name: { type: String, required: true },
  fields: [{
    name: String,
    type: { 
      type: String,
      enum: ['String', 'Number', 'Boolean', 'Date', 'ObjectId', 'Array']
    },
    required: Boolean,
    unique: Boolean,
    default: mongoose.Schema.Types.Mixed
  }],
  timestamps: { type: Boolean, default: true }
}, { _id: false });

const projectSchema = new mongoose.Schema({
  name: { 
    type: String, 
    required: true,
    trim: true
  },
  description: String,
  owner: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User',
    required: true
  },
  widgets: [widgetSchema],
  screens: [{
    id: String,
    name: String,
    route: String,
    widgets: [widgetSchema]
  }],
  theme: {
    primaryColor: { type: String, default: '#2196F3' },
    accentColor: { type: String, default: '#FF5722' },
    fontFamily: { type: String, default: 'Roboto' },
    darkMode: { type: Boolean, default: false }
  },
  apis: [apiEndpointSchema],
  dataModels: [dataModelSchema],
  flutterCode: String,
  backendCode: String,
  collaborators: [{
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    role: { type: String, enum: ['viewer', 'editor', 'admin'] }
  }]
}, {
  timestamps: true
});
projectSchema.index({ owner: 1 });
projectSchema.index({ name: 'text', description: 'text' });
projectSchema.index({ createdAt: -1 });
// module.exports = mongoose.model('Project', projectSchema);

export const Project = mongoose.model('Project', projectSchema);