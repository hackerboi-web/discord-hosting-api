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
