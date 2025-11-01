const express = require('express');
const app = express();

// Match ECS task definition (port 8080)
const port = process.env.PORT || 8080;

app.get('/', (req, res) => {
  res.send('print ip next');
});

app.listen(port, '0.0.0.0', () => {
  console.log(`✅ Server running on port ${port}`);
});
