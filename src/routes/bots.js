const express = require('express');
const router = express.Router();
const { getBots, createBot, deleteBot } = require('../controllers/botController');

router.get('/', getBots);
router.post('/', createBot);
router.delete('/:id', deleteBot);

module.exports = router;
