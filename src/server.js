require('dotenv').config();
const http = require('http');
const { buildApp } = require('./app');

const PORT = process.env.PORT || 3000;
const app = buildApp();
const server = http.createServer(app);

server.listen(PORT, () => {
  console.log(`Server listening on port ${PORT} (NODE_ENV=${process.env.NODE_ENV})`);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    process.exit(0);
  });
});
