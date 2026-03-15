const mockData = require('../mockData');

const getBots = (req, res) => {
  const bots = mockData.bots.filter(bot => bot.owner_id === req.user.email);
  res.json(bots);
};

const createBot = (req, res) => {
  const { name } = req.body;
  const newBot = {
    id: Date.now(),
    owner_id: req.user.email,
    name,
    status: 'stopped',
    fleet_id: null
  };
  mockData.bots.push(newBot);
  res.status(201).json(newBot);
};

const deleteBot = (req, res) => {
  const botId = parseInt(req.params.id);
  const botIndex = mockData.bots.findIndex(bot => bot.id === botId && bot.owner_id === req.user.email);
  if (botIndex === -1) return res.status(404).json({ error: 'Bot not found' });
  mockData.bots.splice(botIndex, 1);
  res.json({ message: 'Bot deleted' });
};

module.exports = { getBots, createBot, deleteBot };
