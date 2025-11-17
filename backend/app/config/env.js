import { config as loadEnv } from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const envPath = path.resolve(__dirname, '../../.env');

// Load environment variables from the backend/.env file once at startup.
loadEnv({ path: envPath });

// Optional: support a path to a service account JSON or the raw JSON string
const firebaseServiceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH ?? '';
const firebaseServiceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON ?? '';

let serviceAccountData = null;
if (firebaseServiceAccountPath) {
  try {
    const absolute = path.isAbsolute(firebaseServiceAccountPath)
      ? firebaseServiceAccountPath
      : path.resolve(__dirname, '../../', firebaseServiceAccountPath);
    const raw = fs.readFileSync(absolute, 'utf8');
    serviceAccountData = JSON.parse(raw);
  } catch (err) {
    // we'll fall back to JSON env var or ADC
    console.warn('Could not read service account from path:', firebaseServiceAccountPath, err?.message ?? err);
  }
} else if (firebaseServiceAccountJson) {
  try {
    serviceAccountData = JSON.parse(firebaseServiceAccountJson);
  } catch (err) {
    console.warn('Could not parse FIREBASE_SERVICE_ACCOUNT_JSON:', err?.message ?? err);
  }
}

const parsedPort = Number.parseInt(process.env.PORT ?? '3000', 10);

export const env = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: Number.isNaN(parsedPort) ? 3000 : parsedPort,
  firebaseServiceAccount: serviceAccountData, // null if not provided
};

export const isDevelopment = env.nodeEnv !== 'production';
