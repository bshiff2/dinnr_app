import admin from 'firebase-admin';
import { env } from '../config/env.js';

// Initialize Firebase Admin safely. If a service account was provided via env (parsed into env.firebaseServiceAccount), use it.
// Otherwise, fall back to default application credentials (ADC) which requires GOOGLE_APPLICATION_CREDENTIALS to be set,
// or be running in an environment with a default service account (GCP, Cloud Run, etc.).

if (!admin.apps.length) {
  if (env.firebaseServiceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(env.firebaseServiceAccount),
    });
    console.log('Initialized Firebase Admin using service account from env');
  } else {
    // This may throw at runtime if no ADC are available; we catch nothing here so the error surfaces.
    try {
      admin.initializeApp();
      console.warn('Initialized Firebase Admin using default application credentials (ADC).');
    } catch (err) {
      console.error('Failed to initialize Firebase Admin. Provide FIREBASE_SERVICE_ACCOUNT_PATH or FIREBASE_SERVICE_ACCOUNT_JSON in .env.', err?.message ?? err);
      throw err;
    }
  }
}

export default admin;
