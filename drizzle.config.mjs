import 'dotenv/config';

export default {
  schema: './backend/app/db/schema.js',
  out: './backend/app/db/migrations',
  driver: 'pg',
  dbCredentials: {
    connectionString: process.env.NEON_DATABASE_URL ?? process.env.DATABASE_URL,
  },
  dialect: 'postgresql',
};
