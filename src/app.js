const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const compression = require('compression');

const authRoutes = require('./routes/auth');
const botRoutes = require('./routes/bots');
const instanceRoutes = require('./routes/instances');
const fleetRoutes = require('./routes/fleets');
const marketplaceRoutes = require('./routes/marketplace');
const adminRoutes = require('./routes/admin');

const { authMiddleware } = require('./middleware/auth');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

function buildApp() {
  const app = express();

  app.use(helmet());
  app.use(cors());
  app.use(compression());
  app.use(express.json());
  app.use(morgan('combined'));

  app.get('/health', (req, res) => res.json({ status: 'ok' }));

  app.use('/api/auth', authRoutes);
  app.use('/api/bots', authMiddleware, botRoutes);
  app.use('/api/instances', authMiddleware, instanceRoutes);
  app.use('/api/fleets', authMiddleware, fleetRoutes);
  app.use('/api/marketplace', authMiddleware, marketplaceRoutes);
  app.use('/api/admin', authMiddleware, adminRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}

module.exports = { buildApp };
