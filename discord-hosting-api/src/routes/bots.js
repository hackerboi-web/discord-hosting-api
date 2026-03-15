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
