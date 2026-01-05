import mongoose from 'mongoose';

class Database {
  constructor() {
    this.connection = null;
  }

  async connect() {
    try {
      if (this.connection) {
        console.log('📦 Database already connected');
        return this.connection;
      }

      const mongoUri = process.env.MONGODB_URI;
      if (!mongoUri) {
        throw new Error('MONGODB_URI environment variable is not defined');
      }

      this.connection = await mongoose.connect(mongoUri, {
        maxPoolSize: 10,
        serverSelectionTimeoutMS: 5000,
        socketTimeoutMS: 45000,
      });

      console.log('✅ MongoDB connected successfully');
      return this.connection;
    } catch (error) {
      console.error('❌ MongoDB connection error:', error.message);
      throw error;
    }
  }

  async disconnect() {
    try {
      if (this.connection) {
        await mongoose.disconnect();
        this.connection = null;
        console.log('📦 Database disconnected');
      }
    } catch (error) {
      console.error('❌ Database disconnection error:', error.message);
      throw error;
    }
  }

  getConnection() {
    return this.connection;
  }

  isConnected() {
    return mongoose.connection.readyState === 1;
  }
}

// Create singleton instance
const database = new Database();

// Handle process termination
process.on('SIGINT', async () => {
  await database.disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await database.disconnect();
  process.exit(0);
});

export default database;
