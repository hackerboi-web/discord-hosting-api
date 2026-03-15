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
