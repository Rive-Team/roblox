const http = require('http'), https = require('https'), crypto = require('crypto');
const GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11', PORT = 43210, CRLF = String.fromCharCode(13, 10);

const server = http.createServer((req, res) => {
  if (req.url === '/health') { res.writeHead(200); res.end('{"ok":true,"transport":"ws"}'); return; }
  res.writeHead(404); res.end();
});

server.on('upgrade', (req, socket, head) => {
  const key = req.headers['sec-websocket-key'];
  if (!key) return socket.destroy();
  socket.setNoDelay(true);
  socket.write('HTTP/1.1 101 Switching Protocols' + CRLF + 'Upgrade: websocket' + CRLF
    + 'Connection: Upgrade' + CRLF + 'Sec-WebSocket-Accept: '
    + crypto.createHash('sha1').update(key + GUID).digest('base64') + CRLF + CRLF);
  console.log('[relay] client connected (' + (req.headers.origin || '?') + ')');
  attach(socket, head);
});

function frame(str) {
  const p = Buffer.from(str, 'utf8');
  let h;
  if (p.length < 126) { h = Buffer.alloc(2); h[1] = p.length; }
  else if (p.length < 65536) { h = Buffer.alloc(4); h[1] = 126; h.writeUInt16BE(p.length, 2); }
  else { h = Buffer.alloc(10); h[1] = 127; h.writeUInt32BE(0, 2); h.writeUInt32BE(p.length, 6); }
  h[0] = 0x81;
  return Buffer.concat([h, p]);
}

function attach(socket, head) {
  let buf = head && head.length ? Buffer.from(head) : Buffer.alloc(0), frags = [];
  const send = o => { try { socket.write(frame(JSON.stringify(o))); } catch (e) {} };
  const feed = chunk => {
    if (chunk && chunk.length) buf = Buffer.concat([buf, chunk]);
    for (;;) {
      if (buf.length < 2) return;
      const fin = (buf[0] & 0x80) !== 0, op = buf[0] & 0x0f, masked = (buf[1] & 0x80) !== 0;
      let len = buf[1] & 0x7f, off = 2;
      if (len === 126) { if (buf.length < 4) return; len = buf.readUInt16BE(2); off = 4; }
      else if (len === 127) { if (buf.length < 10) return; len = buf.readUInt32BE(6); off = 10; }
      let mask = null;
      if (masked) { if (buf.length < off + 4) return; mask = buf.slice(off, off + 4); off += 4; }
      if (buf.length < off + len) return;
      const pay = Buffer.from(buf.slice(off, off + len));
      if (mask) for (let i = 0; i < pay.length; i++) pay[i] ^= mask[i & 3];
      buf = buf.slice(off + len);
      if (op === 0x8) { try { socket.end(); } catch (e) {} return; }
      if (op === 0x9) { const h = Buffer.alloc(2); h[0] = 0x8a; h[1] = pay.length;
        try { socket.write(Buffer.concat([h, pay])); } catch (e) {} continue; }
      if (op === 0xa) continue;
      if (op === 0x0 || op === 0x1) {
        frags.push(pay);
        if (fin) { const msg = Buffer.concat(frags).toString('utf8'); frags = []; handle(msg, send); }
        continue;
      }
      if (fin) frags = [];
    }
  };
  socket.on('data', feed);
  socket.on('error', () => {});
  socket.on('close', () => console.log('[relay] client disconnected'));
  feed(null);
}

function handle(raw, send) {
  let m;
  try { m = JSON.parse(raw); } catch (e) { return; }
  if (m.op === 'ping') return send({ id: m.id, op: 'pong', ok: true });
  if (m.op !== 'proxy') return send({ id: m.id, op: 'result', ok: false, status: 0, error: 'unknown op' });
  let u;
  try { u = new URL(m.url); } catch (e) { return send({ id: m.id, op: 'result', ok: false, status: 0, error: 'bad url' }); }
  const host = u.hostname;
  if (u.protocol !== 'https:' || !(host === 'discordsays.com' || host.endsWith('.discordsays.com'))) {
    return send({ id: m.id, op: 'result', ok: false, status: 0, error: 'host not allowed' });
  }
  const body = typeof m.body === 'string' ? m.body : '';
  const headers = Object.assign({}, m.headers || {});
  headers['Content-Length'] = Buffer.byteLength(body);
  const r = https.request({ hostname: host, port: 443, path: u.pathname + u.search,
    method: m.method || 'POST', headers }, p => {
    let d = '';
    p.setEncoding('utf8');
    p.on('data', c => d += c);
    p.on('end', () => {
      console.log('[relay] ' + host + u.pathname + ' -> ' + p.statusCode);
      send({ id: m.id, op: 'result', ok: p.statusCode < 400, status: p.statusCode, body: d });
    });
  });
  r.on('error', e => send({ id: m.id, op: 'result', ok: false, status: 0, error: e.message }));
  if (body) r.write(body);
  r.end();
}

server.on('error', e => {
  console.error(e.code === 'EADDRINUSE'
    ? 'Port ' + PORT + ' is already in use - stop the old relay first.' : e.message);
  process.exit(1);
});
server.listen(PORT, '127.0.0.1', () => console.log('Orion Relay (WebSocket) ready on ws://127.0.0.1:' + PORT));
