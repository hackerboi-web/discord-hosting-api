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
