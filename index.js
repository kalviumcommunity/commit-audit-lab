const express = require('express');
const app = express();
app.use(express.json());

app.get('/', (req, res) => res.send('Auth service running'));

module.exports = app;
console.log('debug');
// old logging patch
