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
