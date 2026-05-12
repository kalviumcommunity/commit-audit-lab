#!/bin/bash

# ─────────────────────────────────────────────
# CONFIGURATION
REPO_OWNER="kalviumcommunity"
REPO_NAME="commit-audit-lab"
REMOTE_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
# ─────────────────────────────────────────────

set -e

echo "📁 Setting up bad repository forensic targets in: ${PWD}"

git config user.name "devops-bot"
git config user.email "devops-bot@example.com"

# ── COMMIT 1: Initial project structure ──
mkdir -p src/auth src/routes src/middleware
cat > README.md << 'INNEREOF'
# commit-audit-lab

A Node.js authentication service.
INNEREOF

cat > package.json << 'INNEREOF'
{
  "name": "commit-audit-lab",
  "version": "1.0.0",
  "description": "Auth service",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  }
}
INNEREOF

cat > index.js << 'INNEREOF'
const express = require('express');
const app = express();
app.use(express.json());

app.get('/', (req, res) => res.send('Auth service running'));

module.exports = app;
INNEREOF

git add .
git commit -m "feat(init): scaffold Node.js authentication service"

# ── COMMIT 2: Add JWT middleware ──
cat > src/middleware/auth.js << 'INNEREOF'
const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });

  const secret = process.env.JWT_SECRET;
  jwt.verify(token, secret, (err, decoded) => {
    if (err) return res.status(403).json({ error: 'Invalid token' });
    req.user = decoded;
    next();
  });
};

module.exports = { verifyToken };
INNEREOF

git add .
git commit -m "feat(auth): add JWT verification middleware with env secret"

# ── COMMIT 3: Add user routes ──
cat > src/routes/user.js << 'INNEREOF'
const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');

router.get('/profile', verifyToken, (req, res) => {
  res.json({ user: req.user });
});

module.exports = router;
INNEREOF

git add .
git commit -m "feat(routes): add protected user profile endpoint"

# ── COMMIT 4: Bad commit ──
echo "# TODO: cleanup" >> README.md
cat >> package.json << 'INNEREOF'

INNEREOF
cat > src/middleware/auth.js << 'INNEREOF'
const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });

  const secret = process.env.JWT_SECRET || 'fallback-dev-key';
  jwt.verify(token, secret, (err, decoded) => {
    if (err) return res.status(403).json({ error: 'Invalid token' });
    req.user = decoded;
    next();
  });
};

module.exports = { verifyToken };
INNEREOF

git add .
git commit -m "fix"

# ── COMMIT 5: Another vague commit ──
echo "console.log('debug');" >> index.js
git add .
git commit -m "update"

# ── COMMIT 6: Create feature branch ──
git checkout -b feature/token-refresh

cat > src/routes/refresh.js << 'INNEREOF'
const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');

router.post('/refresh', (req, res) => {
  const { token } = req.body;
  if (!token) return res.status(400).json({ error: 'Token required' });
  
  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) return res.status(403).json({ error: 'Invalid token' });
    const newToken = jwt.sign({ id: decoded.id }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.json({ token: newToken });
  });
});

module.exports = router;
INNEREOF

git add .
git commit -m "feat(auth): implement token refresh endpoint"

mkdir -p tests
cat > tests/auth.test.js << 'INNEREOF'
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
INNEREOF

git add .
git commit -m "asdf"

# ── Merge feature branch to main ──
git checkout main
git merge feature/token-refresh -m "merge branch stuff"

# ── COMMIT 7: Simulate a commit that gets immediately reverted ──
cat > src/routes/admin.js << 'INNEREOF'
const express = require('express');
const router = express.Router();

// WARNING: no auth guard — anyone can hit this
router.delete('/users/:id', (req, res) => {
  res.json({ deleted: req.params.id });
});

module.exports = router;
INNEREOF

git add .
git commit -m "feat(admin): add admin delete user route"

# ── COMMIT 8: Panic revert ──
git revert HEAD --no-edit

# ── COMMIT 9: Simulate force-push evidence ──
SAVED_HEAD=$(git rev-parse HEAD)
echo "// experimental load balancer hook" >> index.js
git add .
git commit -m "wip load balancer"
git reset --hard HEAD~1

# ── COMMIT 10: Resume with another vague commit ──
cat >> README.md << 'INNEREOF'

## Deployment

Run `node index.js` to start.
INNEREOF
git add .
git commit -m "changes"

# ── COMMIT 11: Revert of the original revert ──
REVERT_HASH=$(git log --oneline | grep "Revert" | head -1 | awk '{print $1}')
git revert "${REVERT_HASH}" --no-edit

# ── Add a second stale branch ──
git checkout -b fix/old-logging
echo "// old logging patch" >> index.js
git add .
git commit -m "fix logging maybe"
git checkout main

# ── Push everything to remote ──
git push -u origin main
git push origin feature/token-refresh
git push origin fix/old-logging

echo "✅ Bad repository created and pushed successfully."
