import { Pool } from 'pg';

// Create database connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

export const customAdapter = {
  // User operations
  user: {
    findByEmail: async (email: string) => {
      const result = await pool.query(
        'SELECT id, email, name, created_at as "createdAt", updated_at as "updatedAt" FROM users WHERE email = $1',
        [email]
      );
      return result.rows[0] || null;
    },

    findById: async (id: string) => {
      const result = await pool.query(
        'SELECT id, email, name, created_at as "createdAt", updated_at as "updatedAt" FROM users WHERE id = $1',
        [id]
      );
      return result.rows[0] || null;
    },

    create: async (data: { email: string; name?: string; password: string }) => {
      const result = await pool.query(
        'INSERT INTO users (id, email, name, hashed_password, created_at, updated_at) VALUES (gen_random_uuid(), $1, $2, $3, NOW(), NOW()) RETURNING id, email, name, created_at as "createdAt", updated_at as "updatedAt"',
        [data.email, data.name || null, data.password]
      );
      return result.rows[0];
    },

    update: async (id: string, data: Partial<{ email: string; name: string }>) => {
      const updates: string[] = [];
      const values: any[] = [];
      let paramIndex = 1;

      if (data.email) {
        updates.push(`email = $${paramIndex++}`);
        values.push(data.email);
      }
      if (data.name !== undefined) {
        updates.push(`name = $${paramIndex++}`);
        values.push(data.name);
      }

      updates.push(`updated_at = NOW()`);
      values.push(id);

      const result = await pool.query(
        `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING id, email, name, created_at as "createdAt", updated_at as "updatedAt"`,
        values
      );
      return result.rows[0];
    }
  },

  // Account operations (virtual mapping to users table)
  account: {
    findByUserId: async (userId: string) => {
      const result = await pool.query(
        'SELECT id as "userId", $1 as "providerId", hashed_password as password FROM users WHERE id = $2',
        ['credential', userId]
      );
      return result.rows[0] || null;
    },

    updatePassword: async (userId: string, password: string) => {
      await pool.query(
        'UPDATE users SET hashed_password = $1, updated_at = NOW() WHERE id = $2',
        [password, userId]
      );
    }
  }
};
