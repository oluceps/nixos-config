// TCP-only clients use loopback adapters in the container's network=none namespace.
const fs = require('node:fs');
const net = require('node:net');
const { spawn } = require('node:child_process');

const routes = JSON.parse(fs.readFileSync('/realm/routes.json', 'utf8'));
const listeners = routes.map(({ port, socket }) => {
  const server = net.createServer((client) => {
    const upstream = net.createConnection({ path: socket });
    client.on('error', () => upstream.destroy());
    upstream.on('error', () => client.destroy());
    client.pipe(upstream).pipe(client);
  });
  server.on('error', (error) => { console.error(error.message); process.exit(1); });
  return new Promise((resolve) => server.listen(port, '127.0.0.1', () => resolve(server)));
});

// Applications without native Unix listeners publish only this mounted socket.
if (process.env.REALM_INGRESS_PORT) {
  const socket = '/realm/backend/http.sock';
  try { fs.unlinkSync(socket); } catch (error) { if (error.code !== 'ENOENT') throw error; }
  const server = net.createServer((client) => {
    const upstream = net.createConnection({ host: '127.0.0.1', port: Number(process.env.REALM_INGRESS_PORT) });
    client.on('error', () => upstream.destroy());
    upstream.on('error', () => client.destroy());
    client.pipe(upstream).pipe(client);
  });
  server.on('error', (error) => { console.error(error.message); process.exit(1); });
  listeners.push(new Promise((resolve) => server.listen(socket, () => {
    fs.chmodSync(socket, 0o660);
    resolve(server);
  })));
}

Promise.all(listeners).then((servers) => {
  const child = spawn(process.argv[2], process.argv.slice(3), { stdio: 'inherit' });
  for (const sig of ['SIGTERM', 'SIGINT']) process.on(sig, () => child.kill(sig));
  child.on('error', (error) => { console.error(error.message); process.exit(1); });
  child.on('exit', (code) => {
    servers.forEach((server) => server.close());
    process.exit(code === null ? 1 : code);
  });
});
