#!/usr/bin/env bash
set -e

mkdir -p discord-hosting-api
cd discord-hosting-api

npm init -y >/dev/null 2>&1

npm install express cors morgan helmet compression jsonwebtoken bcryptjs uuid express-rate-limit dotenv >/dev/null 2>&1
npm install --save-dev nodemon >/dev/null 2>&1

mkdir -p src/routes src/middleware src/config src/models

cat > src/server.js << 'EOT'
require('dotenv').config();
const http = require('http');
const { buildApp } = require('./app');

const PORT = process.env.PORT || 3000;
const app = buildApp();
const server = http.createServer(app);

server.listen(PORT, () => {
  console.log(\`Server listening on port \${PORT} (NODE_ENV=\${process.env.NODE_ENV})\`);
});
EOT

cat > src/app.js << 'EOT'
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
EOT

cat > src/config/index.js << 'EOT'
if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET is required');
}

const config = {
  env: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 3000),
  jwt: {
    secret: process.env.JWT_SECRET,
    accessExpiresIn: '15m'
  },
  rateLimit: {
    windowMs: 15 * 60 * 1000,
    max: 1000
  }
};

module.exports = config;
EOT

cat > src/middleware/auth.js << 'EOT'
const jwt = require('jsonwebtoken');
const config = require('../config');

function generateAccessToken(user) {
  return jwt.sign(
    { sub: user.id, role: user.role },
    config.jwt.secret,
    { expiresIn: config.jwt.accessExpiresIn }
  );
}

function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing token' });
  }
  const token = header.split(' ')[1];
  try {
    const payload = jwt.verify(token, config.jwt.secret);
    req.user = { id: payload.sub, role: payload.role };
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

function requireRole(role) {
  return (req, res, next) => {
    if (!req.user || req.user.role !== role) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    next();
  };
}

module.exports = { authMiddleware, requireRole, generateAccessToken };
EOT

cat > src/middleware/errorHandler.js << 'EOT'
function notFoundHandler(req, res, next) {
  res.status(404).json({ error: 'Not found' });
}

function errorHandler(err, req, res, next) {
  console.error(err);
  const status = err.status || 500;
  const message = status === 500 ? 'Internal server error' : err.message;
  res.status(status).json({ error: message });
}

module.exports = { errorHandler, notFoundHandler };
EOT

cat > src/middleware/rateLimit.js << 'EOT'
const rateLimit = require('express-rate-limit');
const config = require('../config');

const apiLimiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.max,
  standardHeaders: true,
  legacyHeaders: false
});

module.exports = { apiLimiter };
EOT

cat > src/models/mockData.js << 'EOT'
const { v4: uuid } = require('uuid');

const users = [
  {
    id: uuid(),
    email: 'admin@example.com',
    passwordHash: '$2a$10$examplehash',
    role: 'admin',
    subscriptionTier: 'Enterprise'
  },
  {
    id: uuid(),
    email: 'user@example.com',
    passwordHash: '$2a$10$examplehash',
    role: 'user',
    subscriptionTier: 'Free'
  }
];

const subscriptions = [
  {
    id: uuid(),
    name: 'Free',
    maxBots: 1,
    maxInstances: 1,
    cpuLimit: 0.5,
    ramLimitMb: 512
  },
  {
    id: uuid(),
    name: 'Intermediate',
    maxBots: 3,
    maxInstances: 5,
    cpuLimit: 2,
    ramLimitMb: 4096
  },
  {
    id: uuid(),
    name: 'Professional',
    maxBots: 10,
    maxInstances: 20,
    cpuLimit: 8,
    ramLimitMb: 16384
  },
  {
    id: uuid(),
    name: 'Enterprise',
    maxBots: 50,
    maxInstances: 100,
    cpuLimit: 32,
    ramLimitMb: 65536
  }
];

const bots = [
  {
    id: uuid(),
    ownerId: users[1].id,
    name: 'MyBot',
    status: 'running',
    fleetId: null
  }
];

const instances = [
  {
    id: uuid(),
    botId: bots[0].id,
    planId: subscriptions[0].id,
    name: 'MyBot-Instance-1',
    status: 'running',
    cpuUsage: 0.1,
    ramUsageMb: 256,
    memUsageMb: 50,
    fleetId: null
  }
];

const fleets = [
  {
    id: uuid(),
    ownerId: users[1].id,
    name: 'Prod Fleet',
    mainInstanceId: instances[0].id,
    sharedCpuLimit: 4,
    sharedRamLimitMb: 8192
  }
];

const fleetBots = [
  {
    fleetId: fleets[0].id,
    botId: bots[0].id
  }
];

const transactions = [
  {
    id: uuid(),
    userId: users[1].id,
    subscriptionId: subscriptions[2].id,
    type: 'upgrade',
    amountCents: 999,
    createdAt: new Date().toISOString(),
    metadata: { fromTier: 'Free', toTier: 'Professional' }
  }
];

module.exports = {
  users,
  subscriptions,
  bots,
  instances,
  fleets,
  fleetBots,
  transactions
};
EOT

cat > src/routes/auth.js << 'EOT'
const express = require('express');
const bcrypt = require('bcryptjs');
const { users } = require('../models/mockData');
const { generateAccessToken } = require('../middleware/auth');

const router = express.Router();

router.post('/register', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password)
    return res.status(400).json({ error: 'Email and password required' });

  if (users.find(u => u.email === email))
    return res.status(409).json({ error: 'Email already registered' });

  const hash = await bcrypt.hash(password, 10);
  const user = {
    id: Date.now().toString(),
    email,
    passwordHash: hash,
    role: 'user',
    subscriptionTier: 'Free'
  };
  users.push(user);

  const token = generateAccessToken(user);
  res.status(201).json({
    token,
    user: { id: user.id, email: user.email, role: user.role, subscriptionTier: user.subscriptionTier }
  });
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  const user = users.find(u => u.email === email);
  if (!user) return res.status(401).json({ error: 'Invalid credentials' });

  const ok = await bcrypt.compare(password, user.passwordHash);
  if (!ok) return res.status(401).json({ error: 'Invalid credentials' });

  const token = generateAccessToken(user);
  res.json({
    token,
    user: { id: user.id, email: user.email, role: user.role, subscriptionTier: user.subscriptionTier }
  });
});

module.exports = router;
EOT

cat > src/routes/bots.js << 'EOT'
const express = require('express');
const { v4: uuid } = require('uuid');
const { bots } = require('../models/mockData');

const router = express.Router();

router.get('/', (req, res) => {
  const userBots = bots.filter(b => b.ownerId === req.user.id);
  res.json(userBots);
});

router.post('/', (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ error: 'Name required' });

  const bot = {
    id: uuid(),
    ownerId: req.user.id,
    name,
    status: 'stopped',
    fleetId: null
  };
  bots.push(bot);
  res.status(201).json(bot);
});

router.delete('/:id', (req, res) => {
  const idx = bots.findIndex(b => b.id === req.params.id && b.ownerId === req.user.id);
  if (idx === -1) return res.status(404).json({ error: 'Bot not found' });
  bots.splice(idx, 1);
  res.status(204).send();
});

module.exports = router;
EOT

cat > src/routes/instances.js << 'EOT'
const express = require('express');
const { v4: uuid } = require('uuid');
const { instances, bots } = require('../models/mockData');

const router = express.Router();

router.get('/', (req, res) => {
  const userBotIds = bots.filter(b => b.ownerId === req.user.id).map(b => b.id);
  const userInstances = instances.filter(i => userBotIds.includes(i.botId));
  res.json(userInstances);
});

router.post('/', (req, res) => {
  const { botId, planId, name } = req.body;
  const bot = bots.find(b => b.id === botId && b.ownerId === req.user.id);
  if (!bot) return res.status(404).json({ error: 'Bot not found' });

  const instance = {
    id: uuid(),
    botId,
    planId: planId || null,
    name: name || \`Instance-\${Date.now()}\`,
    status: 'stopped',
    cpuUsage: 0,
    ramUsageMb: 0,
    memUsageMb: 0,
    fleetId: null
  };
  instances.push(instance);
  res.status(201).json(instance);
});

router.patch('/:id/upgrade', (req, res) => {
  const { planId } = req.body;
  const instance = instances.find(i => i.id === req.params.id);
  if (!instance) return res.status(404).json({ error: 'Instance not found' });

  instance.planId = planId || instance.planId;
  res.json(instance);
});

module.exports = router;
EOT

cat > src/routes/fleets.js << 'EOT'
const express = require('express');
const { v4: uuid } = require('uuid');
const { fleets, fleetBots, bots, instances } = require('../models/mockData');

const router = express.Router();

router.get('/', (req, res) => {
  const userFleets = fleets.filter(f => f.ownerId === req.user.id);
  res.json(userFleets);
});

router.post('/', (req, res) => {
  const { name, mainInstanceId, sharedCpuLimit, sharedRamLimitMb } = req.body;
  const instance = instances.find(i => i.id === mainInstanceId);
  if (!instance) return res.status(404).json({ error: 'Main instance not found' });

  const bot = bots.find(b => b.id === instance.botId);
  if (!bot || bot.ownerId !== req.user.id)
    return res.status(403).json({ error: 'Forbidden' });

  const fleet = {
    id: uuid(),
    ownerId: req.user.id,
    name,
    mainInstanceId,
    sharedCpuLimit: sharedCpuLimit || 2,
    sharedRamLimitMb: sharedRamLimitMb || 4096
  };
  fleets.push(fleet);
  res.status(201).json(fleet);
});

router.post('/:fleetId/bots', (req, res) => {
  const { botId } = req.body;
  const fleet = fleets.find(f => f.id === req.params.fleetId && f.ownerId === req.user.id);
  if (!fleet) return res.status(404).json({ error: 'Fleet not found' });

  const bot = bots.find(b => b.id === botId && b.ownerId === req.user.id);
  if (!bot) return res.status(404).json({ error: 'Bot not found' });

  fleetBots.push({ fleetId: fleet.id, botId: bot.id });
  bot.fleetId = fleet.id;
  res.status(201).json({ fleetId: fleet.id, botId: bot.id });
});

router.delete('/:fleetId/bots/:botId', (req, res) => {
  const { fleetId, botId } = req.params;
  const fleet = fleets.find(f => f.id === fleetId && f.ownerId === req.user.id);
  if (!fleet) return res.status(404).json({ error: 'Fleet not found' });

  const idx = fleetBots.findIndex(fb => fb.fleetId === fleetId && fb.botId === botId);
  if (idx === -1) return res.status(404).json({ error: 'Bot not in fleet' });
  fleetBots.splice(idx, 1);

  const bot = bots.find(b => b.id === botId);
  if (bot) bot.fleetId = null;

  res.status(204).send();
});

module.exports = router;
EOT

cat > src/routes/marketplace.js << 'EOT'
const express = require('express');
const { v4: uuid } = require('uuid');
const { subscriptions, transactions } = require('../models/mockData');

const router = express.Router();

router.get('/subscriptions', (req, res) => {
  res.json(subscriptions);
});

router.post('/purchase', (req, res) => {
  const { subscriptionId, type } = req.body;
  const subscription = subscriptions.find(s => s.id === subscriptionId);
  if (!subscription) return res.status(404).json({ error: 'Subscription not found' });

  const tx = {
    id: uuid(),
    userId: req.user.id,
    subscriptionId,
    type: type || 'purchase',
    amountCents: 999,
    createdAt: new Date().toISOString(),
    metadata: {}
  };
  transactions.push(tx);
  res.status(201).json(tx);
});

module.exports = router;
EOT

cat > src/routes/admin.js << 'EOT'
const express = require('express');
const { bots } = require('../models/mockData');
const { requireRole } = require('../middleware/auth');

const router = express.Router();

router.use(requireRole('admin'));

function setBotStatus(botId, status, reason) {
  const bot = bots.find(b => b.id === botId);
  if (!bot) return null;
  bot.status = status;
  bot.lastAdminAction = { status, reason, at: new Date().toISOString() };
  return bot;
}

router.post('/bots/:id/stop', (req, res) => {
  const bot = setBotStatus(req.params.id, 'stopped', req.body.reason || 'Stopped by admin');
  if (!bot) return res.status(404).json({ error: 'Bot not found' });
  res.json(bot);
});

router.post('/bots/:id/suspend', (req, res) => {
  const bot = setBotStatus(req.params.id, 'suspended', req.body.reason || 'Suspended by admin');
  if (!bot) return res.status(404).json({ error: 'Bot not found' });
  res.json(bot);
});

router.post('/bots/:id/warn', (req, res) => {
  const bot = bots.find(b => b.id === req.params.id);
  if (!bot) return res.status(404).json({ error: 'Bot not found' });
  bot.lastAdminWarning = {
    reason: req.body.reason || 'Warned by admin',
    at: new Date().toISOString()
  };
  res.json(bot);
});

router.post('/bots/:id/terminate', (req, res) => {
  const bot = setBotStatus(req.params.id, 'terminated', req.body.reason || 'Terminated by admin');
  if (!bot) return res.status(404).json({ error: 'Bot not found' });
  res.json(bot);
});

module.exports = router;
EOT

cat > .env << 'EOT'
NODE_ENV=development
PORT=3000
JWT_SECRET=super_long_random_secret_here
EOT

# patch package.json scripts
node - << 'EOT'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts = pkg.scripts || {};
pkg.scripts.dev = 'nodemon src/server.js';
pkg.scripts.start = 'node src/server.js';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
EOT

echo "Done. cd discord-hosting-api && npm run dev"
