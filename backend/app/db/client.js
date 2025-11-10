import { neon } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-http';
import { sql } from 'drizzle-orm';

import { env, isDevelopment } from '../config/env.js';

// Reuse HTTP connections between invocations for improved cold-start performance.
const neonClient = neon(env.databaseUrl, {
  fetchConnectionCache: true,
});

export const db = drizzle(neonClient, {
  logger: isDevelopment,
});

export const queryClient = neonClient;

export async function pingDatabase() {
  await db.execute(sql`select 1`);
}
