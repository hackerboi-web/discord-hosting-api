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
