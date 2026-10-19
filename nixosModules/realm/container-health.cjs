const http = require('node:http');
const request = http.get({ socketPath: '/realm/backend/http.sock', path: '/' }, (response) => {
  response.resume();
  process.exit(response.statusCode < 500 ? 0 : 1);
});
request.setTimeout(5000, () => { request.destroy(); process.exit(1); });
request.on('error', () => process.exit(1));
