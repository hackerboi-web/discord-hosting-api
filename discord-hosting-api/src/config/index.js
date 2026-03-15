if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET is required');
}

const config = {
  env: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 3000),
  jwt: {
    secret: process.env.JWT_SECRET,
    accessExpiresIn: '15m'
  },
  rateLimit: {
    windowMs: 15 * 60 * 1000,
    max: 1000
  }
};

module.exports = config;
