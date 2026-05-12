const { verifyToken } = require('../src/middleware/auth');

describe('verifyToken middleware', () => {
  it('should reject requests with no token', () => {
    const req = { headers: {} };
    const res = { status: jest.fn().mockReturnThis(), json: jest.fn() };
    const next = jest.fn();
    verifyToken(req, res, next);
    expect(res.status).toHaveBeenCalledWith(401);
  });
});
