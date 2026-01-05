import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import http from 'http';
import { Server as SocketIOServer } from 'socket.io';
import database from './config/database.js';
import ErrorHandler from './middleware/error_handler.js';
import { HTTP_STATUS, SOCKET_EVENTS } from './config/constants.js';
import ResponseHelper from './utils/response_helper.js';

// Import routes
import authRoutes from './routes/auth_routes.js';
import projectRoutes from './routes/project_routes.js';
import { apiRoutes } from './routes/apiRoutes.js';
import dynamicApiRoutes from './routes/dynamicApiRoutes.js';

class Server {
  constructor() {
    this.app = express();
    this.server = http.createServer(this.app);
    this.io = new SocketIOServer(this.server, {
      cors: {
        origin: process.env.FRONTEND_URL || 'http://localhost:8080',
        methods: ['GET', 'POST', 'PUT', 'DELETE']
      }
    });
    this.port = process.env.PORT || 5001;
  }

  setupMiddleware() {
    // CORS middleware
    this.app.use(cors({
      origin: process.env.FRONTEND_URL || 'http://localhost:8080',
      credentials: true,
    }));

    // Body parsing middleware
    this.app.use(express.json({ limit: '50mb' }));
    this.app.use(express.urlencoded({ extended: true, limit: '50mb' }));

    // Request logging middleware
    this.app.use((req, res, next) => {
      console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
      next();
    });
  }

  setupRoutes() {
    // Health check endpoint
    this.app.get('/health', (req, res) => {
      ResponseHelper.success(res, {
        status: 'OK',
        message: 'Axiom Backend Running',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
      });
    });

    // API routes
    this.app.use('/api/auth', authRoutes);
    this.app.use('/api/projects', projectRoutes);
    this.app.use('/api/apis', apiRoutes);
    this.app.use('/api', dynamicApiRoutes);
  }

  setupWebSocket() {
    this.io.on(SOCKET_EVENTS.CONNECTION, (socket) => {
      console.log(`👤 User connected: ${socket.id}`);

      socket.on(SOCKET_EVENTS.JOIN_PROJECT, (projectId) => {
        socket.join(projectId);
        console.log(`User ${socket.id} joined project ${projectId}`);
      });

      socket.on(SOCKET_EVENTS.LEAVE_PROJECT, (projectId) => {
        socket.leave(projectId);
        console.log(`User ${socket.id} left project ${projectId}`);
      });

      socket.on(SOCKET_EVENTS.WIDGET_UPDATE, (data) => {
        const { projectId, widgetId, updates } = data;
        socket.to(projectId).emit(SOCKET_EVENTS.WIDGET_UPDATED, {
          widgetId,
          updates,
          updatedBy: socket.id,
          timestamp: new Date().toISOString(),
        });
      });

      socket.on(SOCKET_EVENTS.CURSOR_MOVE, (data) => {
        const { projectId, position } = data;
        socket.to(projectId).emit(SOCKET_EVENTS.CURSOR_MOVED, {
          position,
          userId: socket.id,
          timestamp: new Date().toISOString(),
        });
      });

      socket.on(SOCKET_EVENTS.PROJECT_UPDATE, (data) => {
        const { projectId, updates } = data;
        socket.to(projectId).emit(SOCKET_EVENTS.PROJECT_UPDATED, {
          updates,
          updatedBy: socket.id,
          timestamp: new Date().toISOString(),
        });
      });

      socket.on(SOCKET_EVENTS.DISCONNECT, () => {
        console.log(`👤 User disconnected: ${socket.id}`);
      });
    });
  }

  setupErrorHandling() {
    // 404 handler
    this.app.use(ErrorHandler.notFound);

    // Global error handler
    this.app.use(ErrorHandler.handle);
  }

  async start() {
    try {
      // Connect to database
      await database.connect();

      // Setup middleware
      this.setupMiddleware();

      // Setup routes
      this.setupRoutes();

      // Setup WebSocket
      this.setupWebSocket();

      // Setup error handling
      this.setupErrorHandling();

      // Start server
      this.server.listen(this.port, () => {
        console.log(`🚀 Server running on port ${this.port}`);
        console.log(`📊 Health check: http://localhost:${this.port}/health`);
        console.log(`🔗 WebSocket server ready`);
      });

      // Graceful shutdown
      process.on('SIGTERM', this.gracefulShutdown.bind(this));
      process.on('SIGINT', this.gracefulShutdown.bind(this));

    } catch (error) {
      console.error('❌ Failed to start server:', error);
      process.exit(1);
    }
  }

  async gracefulShutdown(signal) {
    console.log(`\n📦 Received ${signal}. Starting graceful shutdown...`);

    try {
      // Close HTTP server
      await new Promise((resolve) => {
        this.server.close(resolve);
      });
      console.log('📡 HTTP server closed');

      // Close WebSocket server
      this.io.close();
      console.log('🔌 WebSocket server closed');

      // Disconnect from database
      await database.disconnect();
      console.log('📦 Database disconnected');

      console.log('✅ Graceful shutdown completed');
      process.exit(0);
    } catch (error) {
      console.error('❌ Error during graceful shutdown:', error);
      process.exit(1);
    }
  }
}

// Create and start server
const server = new Server();
server.start();

export default server;
