const express = require('express');
const router = express.Router();

// WARNING: no auth guard — anyone can hit this
router.delete('/users/:id', (req, res) => {
  res.json({ deleted: req.params.id });
});

module.exports = router;
