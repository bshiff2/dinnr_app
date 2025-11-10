import { config as loadEnv } from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const envPath = path.resolve(__dirname, '../../.env');

// Load environment variables from the backend/.env file once at startup.
loadEnv({ path: envPath });

const requiredVariables = ['NEON_DATABASE_URL'];
const missingVariables = requiredVariables.filter((name) => {
  const value = process.env[name];
  return typeof value !== 'string' || value.length === 0;
});

if (missingVariables.length > 0) {
  throw new Error(
    `Missing required environment variables: ${missingVariables.join(', ')}`,
  );
}

const parsedPort = Number.parseInt(process.env.PORT ?? '3000', 10);

export const env = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: Number.isNaN(parsedPort) ? 3000 : parsedPort,
  databaseUrl: process.env.NEON_DATABASE_URL ?? process.env.DATABASE_URL,
};

export const isDevelopment = env.nodeEnv !== 'production';
