import express from 'express';
import cors from 'cors';

import { env } from './config/env.js';
import { db, pingDatabase } from './db/client.js';
import { users } from './db/schema.js';

const app = express();

app.use(cors());
app.use(express.json());

app.get('/healthz', (req, res) => {
  res.json({
    status: 'ok',
    environment: env.nodeEnv,
    uptimeSeconds: process.uptime(),
  });
});

app.get('/healthz/db', async (req, res, next) => {
  const startedAt = Date.now();

  try {
    await pingDatabase();
    res.json({
      status: 'ok',
      latencyMs: Date.now() - startedAt,
    });
  } catch (error) {
    next(error);
  }
});

app.get('/users', async (_req, res, next) => {
  try {
    const result = await db.select().from(users);
    res.json({ data: result });
  } catch (error) {
    next(error);
  }
});

app.post('/users', async (req, res, next) => {
  const email = typeof req.body?.email === 'string' ? req.body.email.trim() : '';

  if (email.length === 0) {
    res.status(400).json({ error: 'email is required' });
    return;
  }

  try {
    const [created] = await db.insert(users).values({ email }).returning();
    res.status(201).json({ data: created });
  } catch (error) {
    if (error?.code === '23505') {
      res.status(409).json({ error: 'email already exists' });
      return;
    }
    next(error);
  }
});

app.use((error, req, res, _next) => {
  console.error('Unhandled error', error);
  res.status(500).json({ error: 'Internal Server Error' });
});

app.listen(env.port, () => {
  console.log(`Backend listening on port ${env.port}`);
});
