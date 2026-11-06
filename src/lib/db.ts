import { neon } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-serverless';

import * as schema from '@/src/db/schema';

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL is not set. Set it in your .env for local development.');
}

const client = neon(connectionString);
export const sql = client;
export const db = drizzle(connectionString, { schema });

export type Db = typeof db;
