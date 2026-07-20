const request = require('supertest');
const app = require('../app');
const { Pool } = require('pg');

// Mock pg module
jest.mock('pg', () => {
  const mPool = {
    query: jest.fn(),
  };
  return { Pool: jest.fn(() => mPool) };
});

// Mock firebase-admin
jest.mock('firebase-admin', () => {
  return {
    initializeApp: jest.fn(),
    credential: {
      cert: jest.fn()
    },
    auth: () => ({
      verifyIdToken: jest.fn().mockImplementation((token) => {
        if (token === 'owner-token') return Promise.resolve({ uid: 'owner_firebase_uid' });
        if (token === 'player-token') return Promise.resolve({ uid: 'player_firebase_uid' });
        return Promise.reject(new Error('Invalid token'));
      })
    })
  };
});

describe('API RBAC Tests', () => {
  let pool;

  beforeEach(() => {
    pool = new Pool();
    jest.clearAllMocks();
  });

  describe('Academy Invites POST /academy/:academyId/invite', () => {
    it('returns 401 without auth token', async () => {
      const res = await request(app).post('/academy/1/invite');
      expect(res.statusCode).toEqual(401);
    });

    it('allows Academy Owner to send an invite', async () => {
      // Mock owner verification query
      pool.query.mockImplementationOnce(() => Promise.resolve({
        rows: [{ owner_uid: 'owner_firebase_uid' }]
      }));
      
      // Mock inviter ID lookup
      pool.query.mockImplementationOnce(() => Promise.resolve({
        rows: [{ id: 1 }]
      }));
      
      // Mock checking existing user
      pool.query.mockImplementationOnce(() => Promise.resolve({ rows: [] }));
      
      // Mock inserting pending invite
      pool.query.mockImplementationOnce(() => Promise.resolve({
        rows: [{ email: 'test@test.com', role: 'player' }]
      }));

      const res = await request(app)
        .post('/academy/1/invite')
        .send({ email: 'test@test.com', role: 'player' })
        .set('Authorization', 'Bearer owner-token');
      
      expect(res.statusCode).toEqual(201);
    });

    it('forbids non-owner from sending an invite', async () => {
      // Mock owner verification query returning empty rows
      pool.query.mockImplementationOnce(() => Promise.resolve({
        rows: [] 
      }));

      const res = await request(app)
        .post('/academy/1/invite')
        .send({ email: 'test@test.com', role: 'player' })
        .set('Authorization', 'Bearer player-token');
      
      expect(res.statusCode).toEqual(403);
      expect(res.body.message).toBe('Only the Academy Owner can send invites');
    });
  });

  describe('Remove Academy Member DELETE /academy/:academyId/members/:userId', () => {
    it('allows Academy Owner to remove a member', async () => {
      // Mock owner verification query
      pool.query.mockImplementationOnce(() => Promise.resolve({
        rows: [{ owner_uid: 'owner_firebase_uid' }]
      }));
      
      // Mock update query
      pool.query.mockImplementationOnce(() => Promise.resolve({
        rowCount: 1
      }));

      const res = await request(app)
        .delete('/academy/1/members/2')
        .set('Authorization', 'Bearer owner-token');
      
      expect(res.statusCode).toEqual(200);
    });

    it('forbids non-owner from removing a member', async () => {
      // Mock owner verification query returning empty rows
      pool.query.mockImplementationOnce(() => Promise.resolve({
        rows: [] 
      }));

      const res = await request(app)
        .delete('/academy/1/members/2')
        .set('Authorization', 'Bearer player-token');
      
      expect(res.statusCode).toEqual(403);
      expect(res.body.message).toBe('Only the Academy Owner can remove members');
    });
  });
});
