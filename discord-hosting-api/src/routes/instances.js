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
    name: name || `Instance-${Date.now()}`,
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
