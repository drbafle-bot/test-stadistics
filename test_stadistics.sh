#!/bin/bash
set -e

PROJECT_DIR="/opt/test-inteligencias"
CONTAINER_NAME="test-inteligencias"
IMAGE_NAME="test-inteligencias:latest"
PORT="9050"

# Credenciales del panel /tests. CAMBIA ESTO antes de desplegar en producción.
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

echo "==> Creando estructura en $PROJECT_DIR"
sudo mkdir -p "$PROJECT_DIR/public" "$PROJECT_DIR/data"

echo "==> Escribiendo Dockerfile"
sudo tee "$PROJECT_DIR/Dockerfile" > /dev/null <<'DOCKERFILE_EOF'
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev --no-audit --no-fund
COPY server.js ./
COPY public ./public
RUN mkdir -p /app/data
EXPOSE 80
ENV PORT=80
CMD ["node", "server.js"]
DOCKERFILE_EOF

echo "==> Escribiendo package.json"
sudo tee "$PROJECT_DIR/package.json" > /dev/null <<'PKG_EOF'
{
  "name": "perfil-profesional",
  "version": "1.0.0",
  "private": true,
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2"
  }
}
PKG_EOF

echo "==> Escribiendo server.js"
sudo tee "$PROJECT_DIR/server.js" > /dev/null <<'SERVER_EOF'
const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 80;
const DATA_DIR = path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'results.json');

/* Credenciales del panel de empresa. admin/admin por defecto SOLO porque se pidió
   explícitamente así — se recomienda sobrescribir con variables de entorno
   ADMIN_USER / ADMIN_PASSWORD al arrancar el contenedor. */
const ADMIN_USER = process.env.ADMIN_USER || 'admin';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'admin';

if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
if (!fs.existsSync(DATA_FILE)) fs.writeFileSync(DATA_FILE, '[]');

function loadResults() {
  try { return JSON.parse(fs.readFileSync(DATA_FILE, 'utf8')); }
  catch (e) { return []; }
}
function saveResults(list) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(list, null, 2));
}

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, encoded] = header.split(' ');
  if (scheme === 'Basic' && encoded) {
    const decoded = Buffer.from(encoded, 'base64').toString('utf8');
    const sep = decoded.indexOf(':');
    const user = decoded.slice(0, sep);
    const pass = decoded.slice(sep + 1);
    if (user === ADMIN_USER && pass === ADMIN_PASSWORD) return next();
  }
  res.set('WWW-Authenticate', 'Basic realm="Panel empresa"');
  return res.status(401).send('Autenticación requerida.');
}

function escapeHtml(str) {
  return String(str).replace(/[&<>"']/g, c => ({
    '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;'
  }[c]));
}

const BASE_STYLE = `
  :root{ --bg:#1c1e22; --accent:#FF9500; --accent2:#FFB347; --glass:rgba(255,255,255,0.055);
    --glass-border:rgba(255,255,255,0.10); --text:#f4f4f5; --text-dim:#9aa0a8;
    --warn:#e05a4e; --ok:#3ecf8e; }
  *{box-sizing:border-box;margin:0;padding:0;}
  body{font-family:'Manrope',system-ui,sans-serif;background:var(--bg);color:var(--text);padding:32px;
    background:radial-gradient(circle at 12% 8%, rgba(255,149,0,0.10), transparent 40%), var(--bg);}
  h1{font-family:'Outfit',sans-serif;font-weight:800;font-size:1.6rem;margin-bottom:18px;}
  a{color:var(--accent);text-decoration:none;}
  a:hover{text-decoration:underline;}
  table{width:100%;border-collapse:collapse;background:var(--glass);border:1px solid var(--glass-border);border-radius:14px;overflow:hidden;}
  th,td{padding:12px 14px;text-align:left;font-size:.9rem;border-bottom:1px solid var(--glass-border);}
  th{color:var(--text-dim);font-weight:600;font-size:.78rem;text-transform:uppercase;letter-spacing:.04em;}
  tr:last-child td{border-bottom:none;}
  .badge{display:inline-block;padding:3px 10px;border-radius:20px;font-size:.72rem;font-weight:700;}
  .badge-ok{background:rgba(62,207,142,0.15);color:var(--ok);}
  .badge-mid{background:rgba(255,149,0,0.15);color:var(--accent);}
  .badge-warn{background:rgba(224,90,78,0.15);color:var(--warn);}
  .card{max-width:760px;margin:0 auto;background:var(--glass);border:1px solid var(--glass-border);border-radius:20px;padding:32px;}
  .row{display:flex;justify-content:space-between;padding:10px 0;border-bottom:1px solid var(--glass-border);}
  .row:last-child{border-bottom:none;}
  .label{color:var(--text-dim);}
  .bar-track{height:8px;background:rgba(255,255,255,0.07);border-radius:5px;overflow:hidden;margin:6px 0 4px;}
  .bar-fill{height:100%;background:linear-gradient(90deg,var(--accent),var(--accent2));}
  .search{margin-bottom:16px;}
  .search input{background:var(--glass);border:1px solid var(--glass-border);border-radius:10px;padding:10px 14px;color:var(--text);font-size:.9rem;width:280px;}
  .btn{display:inline-block;background:linear-gradient(90deg,var(--accent),var(--accent2));color:#1a1c20;border:none;padding:10px 18px;border-radius:10px;font-weight:700;cursor:pointer;font-family:'Outfit',sans-serif;text-decoration:none;margin-top:18px;}
  .trash-btn{background:none;border:1px solid var(--glass-border);color:var(--text-dim);border-radius:8px;padding:6px 10px;cursor:pointer;font-size:.9rem;transition:all .15s ease;}
  .trash-btn:hover{border-color:var(--warn);color:var(--warn);background:rgba(224,90,78,0.1);}
  .ethics-link{display:inline-block;margin-bottom:16px;color:var(--accent);font-size:.88rem;font-weight:600;text-decoration:none;}
  .ethics-link:hover{text-decoration:underline;}
`;

function renderListPage(list, q) {
  const rows = list.map(r => `
    <tr>
      <td><a href="/tests/${r.id}">${escapeHtml(r.name)}</a></td>
      <td>${new Date(r.date).toLocaleString('es-ES')}</td>
      <td>${escapeHtml(r.dominant ? r.dominant.name : '-')}</td>
      <td>${r.general}%</td>
      <td><span class="badge ${escapeHtml(r.sincerity ? r.sincerity.badgeClass : '')}">${r.sincerity ? r.sincerity.score : '-'}% · ${escapeHtml(r.sincerity ? r.sincerity.label : '')}</span></td>
      <td>
        <form method="POST" action="/tests/${r.id}/delete" style="margin:0;" onsubmit="return confirm('¿Eliminar el resultado de ${escapeHtml(r.name).replace(/'/g,"\\'")}? Esta acción no se puede deshacer.');">
          <button type="submit" class="trash-btn" title="Eliminar resultado">🗑</button>
        </form>
      </td>
    </tr>`).join('');
  return `<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8">
    <title>Panel de resultados</title><style>${BASE_STYLE}</style></head><body>
    <h1>Resultados guardados (${list.length})</h1>
    <a class="ethics-link" href="/etica.html" target="_blank" rel="noopener">⚠ Recomendaciones éticas para la empresa</a>
    <form class="search" method="get" action="/tests">
      <input type="text" name="q" placeholder="Buscar por nombre..." value="${escapeHtml(q)}">
    </form>
    <table>
      <tr><th>Candidato/a</th><th>Fecha</th><th>Perfil dominante</th><th>Desarrollo general</th><th>Sinceridad</th><th></th></tr>
      ${rows || '<tr><td colspan="6">Sin resultados todavía.</td></tr>'}
    </table>
    </body></html>`;
}

function renderDetailPage(record) {
  const rolesRows = (record.roles || []).slice().sort((a,b)=>b.pct-a.pct).map(r => `
    <div class="row" style="display:block;">
      <div class="row" style="border:none;padding:0;"><span>${escapeHtml(r.name)}</span><span>${r.pct}%</span></div>
      <div class="bar-track"><div class="bar-fill" style="width:${r.pct}%"></div></div>
    </div>`).join('');
  const traitsRows = (record.traits || []).map(t => `
    <div class="row" style="display:block;">
      <div class="row" style="border:none;padding:0;"><span>${escapeHtml(t.name)}</span><span>${t.pct}%</span></div>
      <div class="bar-track"><div class="bar-fill" style="width:${t.pct}%"></div></div>
    </div>`).join('');

  // JSON incrustado de forma segura para el generador de PDF del navegador
  const recordJson = JSON.stringify(record).replace(/</g, '\\u003c');

  return `<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8">
    <title>${escapeHtml(record.name)} · Resultado</title><style>${BASE_STYLE}</style>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    </head><body>
    <div class="card">
      <p><a href="/tests">&larr; Volver al listado</a></p>
      <h1>${escapeHtml(record.name)}</h1>
      <div class="row"><span class="label">Fecha</span><span>${new Date(record.date).toLocaleString('es-ES')}</span></div>
      <div class="row"><span class="label">Perfil dominante</span><span>${escapeHtml(record.dominant ? record.dominant.name : '-')} (${record.dominant ? record.dominant.pct : '-'}%)</span></div>
      <div class="row"><span class="label">Desarrollo general</span><span>${record.general}%</span></div>
      <div class="row"><span class="label">Sinceridad / fiabilidad</span><span class="badge ${record.sincerity ? record.sincerity.badgeClass : ''}">${record.sincerity ? record.sincerity.score : '-'}% · ${escapeHtml(record.sincerity ? record.sincerity.label : '')}</span></div>
      <h1 style="font-size:1.1rem;margin-top:24px;">Perfil por área</h1>
      ${rolesRows}
      <h1 style="font-size:1.1rem;margin-top:24px;">Rasgos de comportamiento</h1>
      ${traitsRows}
      <button class="btn" onclick="downloadPdf()">⬇ Descargar informe completo (PDF)</button>
      <p style="color:var(--text-dim);font-size:.78rem;margin-top:20px;">Resultado orientativo de autoevaluación. No debe emplearse como único criterio de contratación, promoción o evaluación de desempeño.</p>
    </div>
    <script>
      const RECORD = ${recordJson};

      function stripAccents(str){
        return String(str).normalize('NFD').replace(/[\\u0300-\\u036f]/g,'');
      }

      function buildPdf(){
        const { jsPDF } = window.jspdf;
        const doc = new jsPDF({ unit:'mm', format:'a4' });
        const pageW = doc.internal.pageSize.getWidth();
        const marginX = 16;
        const contentW = pageW - marginX*2;
        const ACCENT = [255,149,0];
        const ACCENT2 = [255,179,71];
        const DARK = [30,32,36];
        const GREY = [120,124,130];
        const LIGHT = [244,245,247];

        function drawBar(x, y, w, label, pct, valueText){
          doc.setFont('helvetica','bold'); doc.setFontSize(9.5); doc.setTextColor(...DARK);
          doc.text(stripAccents(label), x, y);
          doc.setFont('helvetica','bold'); doc.setFontSize(9.5); doc.setTextColor(...ACCENT);
          doc.text(valueText, x + w, y, { align:'right' });
          doc.setFillColor(235,236,239);
          doc.roundedRect(x, y+2, w, 2.6, 1.3, 1.3, 'F');
          doc.setFillColor(...ACCENT);
          doc.roundedRect(x, y+2, Math.max(w*(pct/100), 3), 2.6, 1.3, 1.3, 'F');
        }

        /* Cabecera de color */
        doc.setFillColor(...ACCENT);
        doc.rect(0, 0, pageW, 30, 'F');
        doc.setFont('helvetica','bold'); doc.setFontSize(17); doc.setTextColor(255,255,255);
        doc.text(stripAccents('Informe de Perfil Profesional'), marginX, 14);
        doc.setFont('helvetica','normal'); doc.setFontSize(10.5);
        const fecha = new Date(RECORD.date).toLocaleDateString('es-ES', {year:'numeric',month:'long',day:'numeric'});
        doc.text(stripAccents(RECORD.name + '  ·  ' + fecha), marginX, 22);

        let y = 42;

        /* Tarjetas de resumen */
        const cardW = (contentW - 10) / 3;
        const cardX = [marginX, marginX+cardW+5, marginX+2*(cardW+5)];
        const cardH = 26;
        const dominant = RECORD.dominant || {name:'-', pct:0};
        const sinc = RECORD.sincerity || {score:0,label:'-'};
        const cardsData = [
          { label:'PERFIL DOMINANTE', big: dominant.pct + '%', sub: stripAccents(dominant.name) },
          { label:'DESARROLLO GENERAL', big: RECORD.general + '%', sub:'Media de las 8 areas' },
          { label:'SINCERIDAD', big: sinc.score + '%', sub: stripAccents(sinc.label) }
        ];
        cardsData.forEach((c, i)=>{
          doc.setFillColor(...LIGHT);
          doc.roundedRect(cardX[i], y, cardW, cardH, 3, 3, 'F');
          doc.setFont('helvetica','bold'); doc.setFontSize(7.5); doc.setTextColor(...GREY);
          doc.text(c.label, cardX[i]+6, y+8);
          doc.setFont('helvetica','bold'); doc.setFontSize(17); doc.setTextColor(...DARK);
          doc.text(c.big, cardX[i]+6, y+18);
          doc.setFont('helvetica','normal'); doc.setFontSize(8); doc.setTextColor(...GREY);
          doc.text(c.sub, cardX[i]+6, y+23, { maxWidth: cardW-10 });
        });
        y += cardH + 12;

        /* Perfil por area */
        doc.setFont('helvetica','bold'); doc.setFontSize(11); doc.setTextColor(...DARK);
        doc.text(stripAccents('Perfil por area'), marginX, y);
        doc.setDrawColor(...ACCENT2); doc.setLineWidth(0.6);
        doc.line(marginX, y+2.5, marginX+contentW, y+2.5);
        y += 11;
        (RECORD.roles || []).slice().sort((a,b)=>b.pct-a.pct).forEach(r=>{
          drawBar(marginX, y, contentW, r.name, r.pct, r.pct + '%');
          y += 10.5;
        });

        y += 4;

        /* Rasgos de comportamiento */
        doc.setFont('helvetica','bold'); doc.setFontSize(11); doc.setTextColor(...DARK);
        doc.text(stripAccents('Rasgos de comportamiento'), marginX, y);
        doc.setDrawColor(...ACCENT2); doc.setLineWidth(0.6);
        doc.line(marginX, y+2.5, marginX+contentW, y+2.5);
        y += 11;
        (RECORD.traits || []).forEach(t=>{
          const poles = '(' + (t.poleLow||'') + ' -> ' + (t.poleHigh||'') + ')';
          drawBar(marginX, y, contentW, t.name + '  ' + stripAccents(poles), t.pct, t.pct + '%');
          y += 10.5;
        });

        /* Nota de sinceridad + aviso legal, siempre al pie de pagina */
        const footTop = 262;
        doc.setDrawColor(230,230,230); doc.setLineWidth(0.3);
        doc.line(marginX, footTop, marginX+contentW, footTop);
        doc.setFont('helvetica','italic'); doc.setFontSize(7.8); doc.setTextColor(...GREY);
        const note = (sinc.note ? sinc.note + ' ' : '') +
          'Aviso: resultado orientativo de autoevaluacion. No debe emplearse como unico criterio de contratacion, promocion o evaluacion de desempeno.';
        const noteLines = doc.splitTextToSize(stripAccents(note), contentW);
        doc.text(noteLines.slice(0,4), marginX, footTop+5);

        doc.setFont('helvetica','normal'); doc.setFontSize(7.5); doc.setTextColor(...GREY);
        doc.text('Servicio SAT PC · Stadistics', marginX, 289);

        return doc;
      }

      function downloadPdf(){
        const doc = buildPdf();
        const safeName = stripAccents(RECORD.name).replace(/[^a-zA-Z0-9]+/g,'-').toLowerCase();
        const stamp = new Date(RECORD.date).toISOString().slice(0,10).replace(/-/g,'');
        const filename = 'perfil-' + safeName + '-' + stamp + '.pdf';
        const blob = doc.output('blob');
        const url = URL.createObjectURL(blob);
        window.open(url, '_blank');
        doc.save(filename);
        setTimeout(()=>URL.revokeObjectURL(url), 60000);
      }
    </script>
    </body></html>`;
}

app.use(express.json({ limit: '200kb' }));
app.use(express.static(path.join(__dirname, 'public')));

app.post('/api/results', (req, res) => {
  const r = req.body;
  if (!r || !r.name || typeof r.name !== 'string' || !r.name.trim()) {
    return res.status(400).json({ error: 'Falta el nombre del candidato.' });
  }
  const list = loadResults();
  const record = {
    id: Date.now().toString(36) + Math.random().toString(36).slice(2, 8),
    name: r.name.trim().slice(0, 120),
    date: new Date().toISOString(),
    general: r.general,
    dominant: r.dominant,
    roles: r.roles,
    traits: r.traits,
    sincerity: r.sincerity
  };
  list.push(record);
  saveResults(list);
  res.json({ ok: true, id: record.id });
});

app.get('/tests', requireAuth, (req, res) => {
  const list = loadResults().sort((a, b) => new Date(b.date) - new Date(a.date));
  const q = (req.query.q || '').toString();
  const filtered = q ? list.filter(r => r.name.toLowerCase().includes(q.toLowerCase())) : list;
  res.send(renderListPage(filtered, q));
});

app.get('/tests/:id', requireAuth, (req, res) => {
  const list = loadResults();
  const record = list.find(r => r.id === req.params.id);
  if (!record) return res.status(404).send('Resultado no encontrado.');
  res.send(renderDetailPage(record));
});

app.post('/tests/:id/delete', requireAuth, (req, res) => {
  const list = loadResults();
  const filtered = list.filter(r => r.id !== req.params.id);
  saveResults(filtered);
  res.redirect(303, '/tests');
});

app.listen(PORT, () => console.log(`Servidor escuchando en el puerto ${PORT}`));
SERVER_EOF

echo "==> Escribiendo public/index.html"
sudo tee "$PROJECT_DIR/public/index.html" > /dev/null <<'INDEX_EOF'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Perfil Profesional del Empleado</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=Manrope:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{
    --bg:#1c1e22; --bg2:#25282D; --accent:#FF9500; --accent2:#FFB347;
    --glass:rgba(255,255,255,0.055); --glass-strong:rgba(255,255,255,0.09);
    --glass-border:rgba(255,255,255,0.10); --text:#f4f4f5; --text-dim:#9aa0a8;
    --warn:#e05a4e; --ok:#3ecf8e;
  }
  *{box-sizing:border-box;margin:0;padding:0;}
  body{
    font-family:'Manrope',system-ui,sans-serif;
    background:radial-gradient(circle at 12% 8%, rgba(255,149,0,0.10), transparent 40%),
               radial-gradient(circle at 90% 85%, rgba(255,149,0,0.07), transparent 45%), var(--bg);
    color:var(--text); min-height:100vh; display:flex; align-items:center; justify-content:center; padding:24px;
  }
  .card{
    width:100%; max-width:760px; background:var(--glass); border:1px solid var(--glass-border);
    backdrop-filter:blur(22px); -webkit-backdrop-filter:blur(22px); border-radius:24px; padding:40px;
    box-shadow:0 20px 60px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.05); animation:fadeIn .5s ease;
  }
  @keyframes fadeIn{from{opacity:0;transform:translateY(8px);}to{opacity:1;transform:translateY(0);}}
  h1{font-family:'Outfit',sans-serif;font-weight:800;font-size:1.9rem;letter-spacing:-.02em;margin-bottom:6px;}
  h2{font-family:'Outfit',sans-serif;font-weight:700;font-size:1.15rem;margin:26px 0 12px;}
  .accent{background:linear-gradient(90deg,var(--accent),var(--accent2));-webkit-background-clip:text;background-clip:text;color:transparent;}
  p.sub{color:var(--text-dim);margin-bottom:24px;font-size:.95rem;line-height:1.5;}
  input[type=text]{
    width:100%; background:var(--glass); border:1px solid var(--glass-border); border-radius:14px;
    padding:14px 16px; color:var(--text); font-family:'Manrope',sans-serif; font-size:1rem; margin-bottom:16px;
    outline:none; transition:border-color .15s ease;
  }
  input[type=text]:focus{border-color:var(--accent);}
  label{display:block;color:var(--text-dim);font-size:.82rem;margin-bottom:6px;}
  .consent-row{display:flex;align-items:flex-start;gap:10px;color:var(--text-dim);font-size:.85rem;line-height:1.4;margin-bottom:18px;cursor:pointer;}
  .consent-row input[type=checkbox]{margin-top:3px;width:16px;height:16px;accent-color:var(--accent);cursor:pointer;flex-shrink:0;}
  .consent-row a{color:var(--accent);text-decoration:underline;}
  .progress{height:5px;background:rgba(255,255,255,0.07);border-radius:3px;overflow:hidden;margin-bottom:30px;}
  .progress-bar{height:100%;background:linear-gradient(90deg,var(--accent),var(--accent2));width:0%;transition:width .35s cubic-bezier(.4,0,.2,1);box-shadow:0 0 12px rgba(255,149,0,0.5);}
  .qtag{color:var(--accent);font-size:.75rem;font-weight:600;letter-spacing:.08em;text-transform:uppercase;margin-bottom:8px;}
  .question{font-family:'Outfit',sans-serif;font-weight:600;font-size:1.3rem;margin-bottom:26px;min-height:60px;line-height:1.35;}
  .scale{display:flex;justify-content:space-between;gap:10px;margin-bottom:14px;}
  .scale button{flex:1;padding:16px 6px;border-radius:14px;border:1px solid var(--glass-border);background:var(--glass);color:var(--text);cursor:pointer;font-size:.9rem;font-weight:600;font-family:'Manrope',sans-serif;transition:all .18s cubic-bezier(.4,0,.2,1);}
  .scale button:hover{border-color:var(--accent);background:rgba(255,149,0,0.14);transform:translateY(-3px);box-shadow:0 6px 18px rgba(255,149,0,0.18);}
  .scale-labels{display:flex;justify-content:space-between;color:var(--text-dim);font-size:.72rem;margin-bottom:12px;letter-spacing:.03em;}
  .nav{display:flex;justify-content:space-between;margin-top:12px;align-items:center;}
  .nav button{background:none;border:none;color:var(--text-dim);cursor:pointer;font-size:.88rem;font-weight:500;transition:color .15s ease;}
  .nav button:hover{color:var(--accent);}
  .start-btn,.restart-btn{background:linear-gradient(90deg,var(--accent),var(--accent2));color:#1a1c20;border:none;padding:15px 30px;border-radius:14px;font-weight:700;font-family:'Outfit',sans-serif;cursor:pointer;font-size:1rem;letter-spacing:-.01em;transition:transform .15s ease,box-shadow .15s ease;}
  .start-btn:hover,.restart-btn:hover{transform:translateY(-2px);box-shadow:0 10px 24px rgba(255,149,0,0.28);}
  .start-btn:disabled{opacity:.4;cursor:default;transform:none;box-shadow:none;}
  .radar-wrap{display:flex;justify-content:center;margin:12px 0 30px;}
  .result-item{margin-bottom:22px;}
  .result-header{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:7px;}
  .result-rank{color:var(--accent);font-family:'Outfit',sans-serif;font-weight:700;font-size:.8rem;margin-right:8px;}
  .result-name{font-weight:600;font-family:'Outfit',sans-serif;}
  .result-pct{color:var(--accent);font-weight:700;font-family:'Outfit',sans-serif;}
  .bar-track{height:9px;background:rgba(255,255,255,0.07);border-radius:5px;overflow:hidden;margin-bottom:9px;}
  .bar-fill{height:100%;background:linear-gradient(90deg,var(--accent),var(--accent2));width:0%;transition:width 1s cubic-bezier(.16,1,.3,1);}
  .result-desc{color:var(--text-dim);font-size:.87rem;line-height:1.5;margin-bottom:4px;}
  .summary-box{background:var(--glass-strong);border:1px solid var(--glass-border);border-radius:16px;padding:20px 22px;margin-bottom:24px;}
  .summary-row{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:10px;}
  .summary-row:last-child{margin-bottom:0;}
  .summary-label{color:var(--text-dim);font-size:.85rem;}
  .summary-value{font-family:'Outfit',sans-serif;font-weight:700;font-size:1.1rem;}
  .badge{display:inline-block;padding:3px 10px;border-radius:20px;font-size:.72rem;font-weight:700;margin-left:8px;}
  .badge-ok{background:rgba(62,207,142,0.15);color:var(--ok);}
  .badge-mid{background:rgba(255,149,0,0.15);color:var(--accent);}
  .badge-warn{background:rgba(224,90,78,0.15);color:var(--warn);}
  .summary-note{color:var(--text-dim);font-size:.82rem;line-height:1.5;margin-top:10px;}
  .save-note{border-radius:14px;padding:14px 16px;font-size:.85rem;margin:18px 0;border:1px solid var(--glass-border);}
  .save-ok{background:rgba(62,207,142,0.08);color:var(--ok);border-color:rgba(62,207,142,0.25);}
  .save-err{background:rgba(224,90,78,0.08);color:var(--warn);border-color:rgba(224,90,78,0.25);}
  footer{margin-top:30px;text-align:center;color:#5b6067;font-size:.72rem;letter-spacing:.02em;}
</style>
</head>
<body>
<div class="card" id="app"></div>

<script>
/* ---------- Datos: perfiles profesionales orientativos ----------
   Autoevaluación orientativa. No sustituye una entrevista ni debe usarse
   como único criterio de contratación, promoción o evaluación de desempeño. */

const ROLE_TYPES = [
  { id:"tecnico", name:"Técnico", desc:"Diagnostica y resuelve problemas técnicos con método y precisión." },
  { id:"programador", name:"Programador/a", desc:"Piensa en lógica, algoritmos y automatización de procesos." },
  { id:"disenador", name:"Diseñador/a", desc:"Aporta sensibilidad estética y cuida la experiencia visual." },
  { id:"comercial", name:"Comercial", desc:"Se orienta a cerrar acuerdos y generar negocio." },
  { id:"atencion_publico", name:"Cara al público", desc:"Trata directamente con clientes, con paciencia y cercanía." },
  { id:"marketing", name:"Marketing", desc:"Comunica, posiciona la marca y genera contenido." },
  { id:"planificador", name:"Planificador/a", desc:"Organiza procesos, tiempos y proyectos con método." },
  { id:"administrador", name:"Administrador/a", desc:"Gestiona documentación, recursos y tareas administrativas." }
];

const TRAIT_TYPES = [
  { id:"iniciativa", name:"Iniciativa", desc:"Tendencia a actuar por cuenta propia frente a esperar instrucciones.", poleLow:"Pasivo", poleHigh:"Activo" },
  { id:"responsabilidad", name:"Responsabilidad", desc:"Fiabilidad y compromiso con lo que se asume.", poleLow:"Bajo", poleHigh:"Alto" },
  { id:"companerismo", name:"Compañerismo", desc:"Disposición a colaborar y apoyar al equipo.", poleLow:"Bajo", poleHigh:"Alto" }
];

const ALL_CATEGORIES = [...ROLE_TYPES, ...TRAIT_TYPES];

const BANK = {
  tecnico:[
    "Disfruto diagnosticar y resolver averías o fallos técnicos.",
    "Me mantengo al día de nuevas herramientas y tecnologías del sector.",
    "Prefiero solucionar un problema técnico antes que delegarlo.",
    "Me resulta sencillo entender el funcionamiento interno de un sistema.",
    "Disfruto configurar o poner a punto equipos y software.",
    "Cuando algo falla, busco la causa raíz antes de aplicar un parche rápido.",
    "Me siento cómodo trabajando con manuales técnicos o documentación compleja.",
    "Prefiero tareas que requieran precisión técnica a tareas puramente creativas.",
    "Disfruto aprender por mi cuenta cómo funciona una tecnología nueva.",
    "Detecto con facilidad cuándo algo no está bien configurado o instalado."
  ],
  programador:[
    "Disfruto escribir código o automatizar tareas repetitivas.",
    "Pienso de forma natural en pasos lógicos y condiciones.",
    "Me gusta depurar errores hasta encontrar su origen exacto.",
    "Prefiero construir una solución desde cero a usar una ya hecha sin entenderla.",
    "Disfruto aprender nuevos lenguajes o frameworks de programación.",
    "Se me da bien descomponer un problema grande en partes más pequeñas.",
    "Dedico tiempo a optimizar procesos aunque nadie me lo pida.",
    "Me resulta satisfactorio ver un programa funcionando tras varias pruebas.",
    "Prefiero la lógica y el código a las tareas de cara al público.",
    "Disfruto revisar y mejorar código que ya funciona."
  ],
  disenador:[
    "Me fijo en la estética y el equilibrio visual de las cosas.",
    "Disfruto crear o mejorar el diseño de una interfaz o un documento.",
    "Detecto con facilidad cuándo algo visualmente no encaja.",
    "Prefiero cuidar la presentación aunque suponga más tiempo.",
    "Disfruto experimentar con colores, tipografías o composiciones.",
    "Me preocupa la experiencia de quien usa lo que diseño.",
    "Suelo tener ideas visuales antes que soluciones técnicas.",
    "Disfruto dar forma visual a una idea abstracta.",
    "Prefiero mostrar algo con una imagen antes que con texto.",
    "Reviso los detalles visuales varias veces antes de darlo por terminado."
  ],
  comercial:[
    "Disfruto negociar y cerrar acuerdos.",
    "Me motiva alcanzar objetivos de venta o resultados medibles.",
    "Se me da bien detectar qué necesita realmente un cliente.",
    "Disfruto convencer a alguien del valor de un producto o servicio.",
    "No me incomoda el rechazo cuando intento cerrar una venta.",
    "Prefiero el contacto directo con clientes a las tareas administrativas.",
    "Disfruto hacer seguimiento activo de oportunidades de negocio.",
    "Me resulta fácil generar confianza rápidamente con desconocidos.",
    "Disfruto competir por alcanzar una meta o cifra.",
    "Prefiero proponer soluciones comerciales a simplemente ejecutar tareas."
  ],
  atencion_publico:[
    "Disfruto el trato directo y frecuente con clientes.",
    "Mantengo la calma incluso con clientes exigentes o molestos.",
    "Me resulta fácil explicar cosas técnicas en un lenguaje sencillo.",
    "Disfruto ayudar a alguien a resolver su problema en el momento.",
    "Prefiero atender en persona o por teléfono antes que por escrito.",
    "Tengo paciencia para repetir una explicación varias veces si hace falta.",
    "Me preocupa que el cliente se vaya satisfecho, más allá de resolver el ticket.",
    "Se me da bien detectar el estado de ánimo de un cliente al hablar con él.",
    "Disfruto el ritmo dinámico de atender varias consultas seguidas.",
    "Prefiero el contacto humano constante a trabajar aislado."
  ],
  marketing:[
    "Disfruto pensar cómo comunicar algo para que llegue mejor al público.",
    "Se me ocurren ideas para promocionar un producto o servicio.",
    "Me fijo en cómo se posicionan otras marcas o empresas.",
    "Disfruto crear contenido (textos, publicaciones, campañas).",
    "Me interesa entender qué motiva a un cliente a comprar.",
    "Disfruto medir y analizar el resultado de una campaña.",
    "Prefiero pensar en la imagen de marca a largo plazo antes que en la venta puntual.",
    "Se me da bien adaptar un mensaje a distintos públicos.",
    "Disfruto estar al día de tendencias y redes sociales.",
    "Me motiva ver cómo una campaña genera más interés o alcance."
  ],
  planificador:[
    "Disfruto organizar tareas, tiempos y prioridades.",
    "Prefiero tener un plan claro antes de empezar cualquier proyecto.",
    "Se me da bien anticipar problemas antes de que ocurran.",
    "Disfruto crear procesos o checklists que faciliten el trabajo del equipo.",
    "Me incomoda trabajar sin una estructura o calendario definido.",
    "Reviso el avance de un proyecto de forma periódica y metódica.",
    "Prefiero coordinar varias tareas a la vez a centrarme en una sola.",
    "Se me da bien estimar cuánto tiempo llevará una tarea.",
    "Disfruto optimizar la forma en que se organiza el trabajo del equipo.",
    "Detecto fácilmente cuellos de botella en un proceso."
  ],
  administrador:[
    "Disfruto gestionar documentación, facturas o trámites.",
    "Soy meticuloso/a revisando datos, cifras o contratos.",
    "Prefiero el orden y el control a la improvisación.",
    "Se me da bien llevar el control de gastos, plazos o recursos.",
    "Disfruto mantener actualizado un sistema de archivo o base de datos.",
    "Detecto errores administrativos o discrepancias con facilidad.",
    "Prefiero tareas estructuradas y recurrentes a tareas muy variables.",
    "Me resulta satisfactorio cerrar y archivar un trámite correctamente.",
    "Disfruto trabajar con normativa, políticas internas o procedimientos.",
    "Se me da bien priorizar tareas administrativas según su urgencia."
  ],
  iniciativa:[
    "Tomo la iniciativa sin esperar a que me digan qué hacer.",
    "Propongo mejoras aunque no formen parte de mi tarea asignada.",
    "Prefiero actuar y corregir sobre la marcha a esperar instrucciones detalladas.",
    "Me anticipo a los problemas antes de que me los planteen.",
    "Busco activamente nuevas formas de mejorar mi trabajo.",
    "Me cuesta quedarme quieto/a cuando veo algo que se puede mejorar.",
    "Prefiero proponer una solución, aunque no sea perfecta, a no decir nada.",
    "Suelo ser de los primeros en ofrecerme para una tarea nueva.",
    "Disfruto asumir responsabilidades adicionales cuando surgen.",
    "Prefiero actuar rápido y aprender del error a esperarlo todo controlado."
  ],
  responsabilidad:[
    "Cumplo mis plazos y compromisos incluso bajo presión.",
    "Si cometo un error, lo reconozco y lo soluciono sin excusas.",
    "Se puede confiar en que termino lo que empiezo.",
    "Cuido los detalles aunque nadie vaya a revisarlos.",
    "Aviso con antelación si no voy a poder cumplir un compromiso.",
    "Me tomo en serio las tareas aunque parezcan poco importantes.",
    "Prefiero hacer bien un trabajo aunque me lleve más tiempo.",
    "Me hago cargo de las consecuencias de mis decisiones.",
    "Mantengo mi palabra incluso cuando ya nadie la recuerda.",
    "Superviso mi propio trabajo antes de darlo por terminado."
  ],
  companerismo:[
    "Ayudo a un compañero aunque no sea mi tarea directa.",
    "Comparto lo que aprendo con el resto del equipo.",
    "Prefiero el éxito del equipo al reconocimiento individual.",
    "Me preocupo por el ambiente de trabajo, no solo por mi propio rendimiento.",
    "Escucho a mis compañeros sin juzgar antes de opinar.",
    "Reconozco el mérito de otros cuando corresponde.",
    "Estoy dispuesto/a a cubrir a un compañero si lo necesita.",
    "Prefiero resolver un desacuerdo hablando a evitarlo o ignorarlo.",
    "Celebro los logros de mis compañeros como si fueran propios.",
    "Aporto ideas en grupo aunque no sean las mías las que se elijan."
  ]
};

const INFREQUENCY = [
  "Nunca en mi vida he tenido dificultad para tomar una decisión.",
  "Domino con total facilidad todas las áreas de este test, sin ninguna excepción.",
  "Jamás me equivoco cuando juzgo el carácter de otra persona.",
  "Recuerdo con precisión absoluta cualquier conversación que he tenido."
];

const SOCIAL_DESIRABILITY = [
  "Siempre cumplo todas mis promesas, sin excepción.",
  "Nunca he sentido envidia de otra persona.",
  "Jamás pierdo la paciencia, pase lo que pase.",
  "Siempre digo la verdad, incluso cuando resulta incómodo.",
  "Nunca he criticado a alguien a sus espaldas.",
  "Jamás he mentido, ni siquiera por cortesía.",
  "Siempre estoy de buen humor, sin importar las circunstancias.",
  "Nunca me arrepiento de las decisiones que tomo."
];

const CONSISTENCY_PAIRS = [
  { catId:"tecnico", origIndex:0, text:"Resolver averías o fallos técnicos me resulta satisfactorio." },
  { catId:"programador", origIndex:0, text:"Escribir código o automatizar tareas me resulta gratificante." },
  { catId:"disenador", origIndex:1, text:"Crear o mejorar el diseño visual de algo me resulta agradable." },
  { catId:"comercial", origIndex:0, text:"Negociar y cerrar acuerdos me resulta estimulante." },
  { catId:"atencion_publico", origIndex:0, text:"El trato directo y frecuente con clientes me resulta agradable." },
  { catId:"marketing", origIndex:3, text:"Crear contenido o campañas me resulta entretenido." },
  { catId:"planificador", origIndex:0, text:"Organizar tareas y prioridades me resulta satisfactorio." },
  { catId:"administrador", origIndex:0, text:"Gestionar documentación o trámites me resulta agradable." },
  { catId:"iniciativa", origIndex:0, text:"Suelo actuar por iniciativa propia, sin esperar instrucciones." },
  { catId:"responsabilidad", origIndex:0, text:"Suelo cumplir mis compromisos incluso cuando la situación es difícil." },
  { catId:"companerismo", origIndex:0, text:"Suelo ayudar a compañeros aunque no me corresponda directamente." }
];

/* Único test: extenso (10 ítems por categoría) */
const ITEMS_PER_CAT = 10;
const CONSISTENCY_COUNT = 11;

const SCALE = [1,2,3,4,5];

let candidateName = "";
let questions = [];
let current = 0;
let answers = [];
let backUsed = false;
const app = document.getElementById('app');

/* ---------- Construcción del cuestionario ---------- */
function buildQuestions(){
  const primary = [];
  for(let i=0;i<ITEMS_PER_CAT;i++){
    ALL_CATEGORIES.forEach(cat=>{
      const isTrait = TRAIT_TYPES.some(t=>t.id===cat.id);
      primary.push({type: isTrait ? 'trait':'role', catId:cat.id, index:i, text:BANK[cat.id][i]});
    });
  }
  const validity = [];
  INFREQUENCY.forEach((text,i)=>validity.push({type:'infreq', index:i, text}));
  SOCIAL_DESIRABILITY.forEach((text,i)=>validity.push({type:'sd', index:i, text}));
  CONSISTENCY_PAIRS.slice(0,CONSISTENCY_COUNT).forEach(pair=>{
    validity.push({type:'consistency', catId:pair.catId, origIndex:pair.origIndex, text:pair.text});
  });

  const result = [];
  const step = Math.max(1, Math.floor(primary.length / (validity.length + 1)));
  let vi = 0;
  primary.forEach((q, idx)=>{
    result.push(q);
    if((idx+1) % step === 0 && vi < validity.length){ result.push(validity[vi]); vi++; }
  });
  while(vi < validity.length){ result.push(validity[vi]); vi++; }
  return result;
}

/* ---------- Pantallas ---------- */
function renderStart(){
  app.innerHTML = `
    <h1>Perfil <span class="accent">Profesional</span></h1>
    <p class="sub">Autoevaluación orientativa de encaje por áreas de trabajo. 133 preguntas · ~20 minutos.</p>
    <label for="nameInput">Nombre del candidato/a</label>
    <input type="text" id="nameInput" placeholder="Nombre y apellidos" oninput="onFormChange()">
    <label class="consent-row">
      <input type="checkbox" id="consentCheck" onchange="onFormChange()">
      <span>He leído y acepto el <a href="/privacidad.html" target="_blank" rel="noopener">tratamiento de mis datos para este proceso de selección</a>.</span>
    </label>
    <button class="start-btn" id="startBtn" disabled onclick="startTest()">Empezar test →</button>
    <div class="summary-note" style="margin-top:14px;">Orientativo. No sustituye una entrevista ni debe usarse como único criterio de contratación o evaluación de desempeño. El resultado quedará guardado para la empresa.</div>
    <footer>Servicio SAT PC · Stadistics</footer>
  `;
}

function onFormChange(){
  const nameVal = document.getElementById('nameInput').value.trim();
  const consent = document.getElementById('consentCheck').checked;
  document.getElementById('startBtn').disabled = !(nameVal.length > 0 && consent);
}

function startTest(){
  candidateName = document.getElementById('nameInput').value.trim();
  const consent = document.getElementById('consentCheck').checked;
  if(!candidateName || !consent) return;
  questions = buildQuestions();
  answers = new Array(questions.length).fill(null);
  current = 0;
  backUsed = false;
  renderQuestion();
}

function renderQuestion(){
  const q = questions[current];
  const pct = Math.round((current / questions.length) * 100);
  const showBack = current > 0 && !backUsed;
  app.innerHTML = `
    <div class="progress"><div class="progress-bar" style="width:${pct}%"></div></div>
    <div class="qtag">Pregunta ${current+1} / ${questions.length}</div>
    <div class="question">${q.text}</div>
    <div class="scale-labels"><span>Nada de acuerdo</span><span>Totalmente de acuerdo</span></div>
    <div class="scale">${SCALE.map(s=>`<button onclick="answer(${s})">${s}</button>`).join('')}</div>
    <div class="nav"><button onclick="prevQuestion()" ${showBack?'':'style="visibility:hidden"'}>← Anterior</button></div>
  `;
}

function answer(v){
  answers[current] = v;
  backUsed = false; // avanzar rehabilita el "Anterior" para la nueva pregunta
  if(current < questions.length - 1){ current++; renderQuestion(); }
  else { renderResults(); }
}
function prevQuestion(){
  if(current > 0 && !backUsed){
    current--;
    backUsed = true; // no se puede retroceder dos veces seguidas
    renderQuestion();
  }
}

/* ---------- Puntuación ---------- */
function computeCategoryScores(){
  const acc = {};
  ALL_CATEGORIES.forEach(c=>acc[c.id] = {sum:0,count:0});
  questions.forEach((q,idx)=>{
    if(q.type === 'role' || q.type === 'trait'){
      const v = answers[idx] || 0;
      acc[q.catId].sum += v;
      acc[q.catId].count += 1;
    }
  });
  const roles = ROLE_TYPES.map(r=>({...r, pct: Math.round((acc[r.id].sum/(acc[r.id].count*5))*100)}));
  const traits = TRAIT_TYPES.map(t=>({...t, pct: Math.round((acc[t.id].sum/(acc[t.id].count*5))*100)}));
  return { roles, traits };
}

function computeSincerity(){
  let penalty = 0;

  let infreqPenalty = 0;
  questions.forEach((q,idx)=>{
    if(q.type === 'infreq'){
      const v = answers[idx] || 0;
      if(v >= 4) infreqPenalty += (v - 3) * 10;
    }
  });
  penalty += infreqPenalty;

  let sdSum = 0, sdCount = 0;
  questions.forEach((q,idx)=>{
    if(q.type === 'sd'){ sdSum += (answers[idx]||0); sdCount++; }
  });
  let sdPenalty = 0;
  if(sdCount>0){
    const sdAvg = sdSum / sdCount;
    if(sdAvg > 3.2) sdPenalty = (sdAvg - 3.2) * 20;
  }
  penalty += sdPenalty;

  let consPenalty = 0;
  questions.forEach((q,idx)=>{
    if(q.type === 'consistency'){
      const origIdx = questions.findIndex(o=>(o.type==='role'||o.type==='trait') && o.catId===q.catId && o.index===q.origIndex);
      if(origIdx !== -1 && answers[origIdx]!=null && answers[idx]!=null){
        const diff = Math.abs(answers[origIdx] - answers[idx]);
        consPenalty += diff * 6;
      }
    }
  });
  penalty += consPenalty;

  const primaryAnswers = questions.map((q,idx)=> (q.type==='role'||q.type==='trait') ? answers[idx] : null).filter(v=>v!=null);
  const mean = primaryAnswers.reduce((a,b)=>a+b,0) / primaryAnswers.length;
  const variance = primaryAnswers.reduce((a,b)=>a+Math.pow(b-mean,2),0) / primaryAnswers.length;
  let straightPenalty = 0;
  if(variance < 0.3) straightPenalty = 20;
  penalty += straightPenalty;

  const score = Math.max(0, Math.min(100, Math.round(100 - penalty)));
  let label, badgeClass, note;
  if(score >= 80){
    label = "Alta fiabilidad"; badgeClass = "badge-ok";
    note = "Las respuestas son coherentes entre sí y no muestran signos de exageración ni de imagen idealizada.";
  } else if(score >= 50){
    label = "Fiabilidad moderada"; badgeClass = "badge-mid";
    note = "Se detectan algunas inconsistencias o respuestas algo idealizadas. Interpretar con cautela.";
  } else {
    label = "Fiabilidad baja"; badgeClass = "badge-warn";
    note = "Se han detectado varias respuestas inconsistentes o poco plausibles. Este resultado no debería usarse para tomar decisiones.";
  }
  return { score, label, badgeClass, note };
}

/* ---------- Radar SVG ---------- */
function radarSVG(results){
  const n = results.length, size = 280, center = size/2, maxR = 105;
  const angleFor = i => (Math.PI*2*i/n) - Math.PI/2;
  const point = (i,r) => { const a=angleFor(i); return [center+r*Math.cos(a), center+r*Math.sin(a)]; };
  const rings = [0.25,0.5,0.75,1].map(f=>{
    const pts = results.map((_,i)=>point(i,maxR*f).join(',')).join(' ');
    return `<polygon points="${pts}" fill="none" stroke="rgba(255,255,255,0.08)" stroke-width="1"/>`;
  }).join('');
  const axes = results.map((_,i)=>{ const [x,y]=point(i,maxR); return `<line x1="${center}" y1="${center}" x2="${x}" y2="${y}" stroke="rgba(255,255,255,0.07)" stroke-width="1"/>`; }).join('');
  const dataPts = results.map((r,i)=>point(i, maxR*(r.pct/100)).join(',')).join(' ');
  const labels = results.map((r,i)=>{ const [x,y]=point(i,maxR+24); return `<text x="${x}" y="${y}" fill="#9aa0a8" font-size="8.5" font-family="Manrope" text-anchor="middle" dominant-baseline="middle">${r.name.split('/')[0]}</text>`; }).join('');
  return `<svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">${rings}${axes}<polygon points="${dataPts}" fill="rgba(255,149,0,0.22)" stroke="#FF9500" stroke-width="2"/>${labels}</svg>`;
}

/* ---------- Guardado en el servidor ---------- */
async function saveResult(payload){
  try{
    const res = await fetch('/api/results', {
      method:'POST',
      headers:{ 'Content-Type':'application/json' },
      body: JSON.stringify(payload)
    });
    if(!res.ok) throw new Error('respuesta no OK');
    return { ok:true };
  } catch(e){
    return { ok:false };
  }
}

/* ---------- Resultados ---------- */
async function renderResults(){
  const { roles, traits } = computeCategoryScores();
  const sortedRoles = [...roles].sort((a,b)=>b.pct-a.pct);
  const general = Math.round(roles.reduce((a,r)=>a+r.pct,0) / roles.length);
  const dominant = sortedRoles[0];
  const sinc = computeSincerity();

  // Vista del candidato: solo puntuación total y agradecimiento.
  // El desglose completo (perfiles, rasgos, sinceridad) se guarda igualmente
  // en el servidor y queda disponible en el PDF del panel de empresa.
  app.innerHTML = `
    <h1>¡Gracias, <span class="accent">${candidateName}</span>!</h1>
    <p class="sub">Has completado el test. Tu resultado ha quedado registrado.</p>
    <div id="saveStatus"></div>

    <div class="radar-wrap">${radarSVG(roles)}</div>

    <div class="summary-box" style="text-align:center;">
      <div class="summary-label" style="margin-bottom:6px;">Puntuación total</div>
      <div style="font-family:'Outfit',sans-serif;font-weight:800;font-size:2.6rem;background:linear-gradient(90deg,var(--accent),var(--accent2));-webkit-background-clip:text;background-clip:text;color:transparent;">${general}%</div>
    </div>

    <button class="restart-btn" onclick="renderStart()">Nuevo test</button>
    <footer>Servicio SAT PC · Stadistics</footer>
  `;

  const result = await saveResult({ name: candidateName, general, dominant, roles, traits, sincerity: sinc });
  const statusEl = document.getElementById('saveStatus');
  if(result.ok){
    statusEl.innerHTML = `<div class="save-note save-ok">✓ Resultado guardado correctamente.</div>`;
  } else {
    statusEl.innerHTML = `<div class="save-note save-err">⚠ No se ha podido guardar el resultado en el servidor. Comprueba la conexión e inténtalo de nuevo.</div>`;
  }
}

renderStart();
</script>
</body>
</html>
INDEX_EOF

echo "==> Escribiendo public/privacidad.html"
sudo tee "$PROJECT_DIR/public/privacidad.html" > /dev/null <<'PRIV_EOF'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Información sobre protección de datos</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@700;800&family=Manrope:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{ --bg:#1c1e22; --accent:#FF9500; --accent2:#FFB347; --glass:rgba(255,255,255,0.055);
    --glass-border:rgba(255,255,255,0.10); --text:#f4f4f5; --text-dim:#9aa0a8; }
  *{box-sizing:border-box;margin:0;padding:0;}
  body{font-family:'Manrope',system-ui,sans-serif;background:radial-gradient(circle at 12% 8%, rgba(255,149,0,0.10), transparent 40%), var(--bg);
    color:var(--text);padding:40px 20px;display:flex;justify-content:center;}
  .card{max-width:680px;background:var(--glass);border:1px solid var(--glass-border);border-radius:20px;padding:36px;}
  h1{font-family:'Outfit',sans-serif;font-weight:800;font-size:1.5rem;margin-bottom:18px;}
  h2{font-family:'Outfit',sans-serif;font-weight:700;font-size:1rem;margin:22px 0 8px;color:var(--accent);}
  p,li{color:var(--text-dim);font-size:.92rem;line-height:1.6;}
  ul{margin-left:20px;margin-top:6px;}
  strong{color:var(--text);}
</style>
</head>
<body>
<div class="card">
  <h1>Información sobre protección de datos</h1>
  <p>En cumplimiento del Reglamento (UE) 2016/679 (RGPD), te informamos sobre el tratamiento de los datos personales facilitados a través de este test de perfil profesional.</p>

  <h2>Responsable del tratamiento</h2>
  <p>La empresa que utiliza esta herramienta como parte de su proceso de selección.</p>

  <h2>Finalidad</h2>
  <p>Obtener una orientación sobre el perfil profesional y las áreas de mejor encaje del candidato/a, como apoyo complementario dentro del proceso de selección de personal.</p>

  <h2>Base jurídica</h2>
  <p><strong>Consentimiento del interesado</strong> (art. 6.1.a RGPD), prestado mediante la aceptación expresa antes de iniciar el test.</p>

  <h2>Plazo de conservación</h2>
  <p>Tus datos se conservarán <strong>únicamente durante la duración del proceso de selección</strong> para el que te presentas.</p>
  <p>En caso de que resultes <strong>contratado/a</strong>, los datos se conservarán <strong>mientras se mantenga la relación laboral</strong>, siempre que tú, como candidato/a o posteriormente como empleado/a, no manifiestes lo contrario.</p>
  <p>Puedes solicitar la supresión de tus datos en cualquier momento del proceso o durante la relación laboral, sin que ello afecte a la licitud del tratamiento previo.</p>

  <h2>Destinatarios</h2>
  <p>No se cederán datos a terceros, salvo obligación legal.</p>

  <h2>Tus derechos</h2>
  <p>Puedes ejercer en cualquier momento tus derechos de <strong>acceso, rectificación, supresión, oposición, limitación del tratamiento y portabilidad</strong> (arts. 15 a 22 RGPD), así como retirar tu consentimiento sin que ello afecte a la licitud del tratamiento previo a su retirada, dirigiéndote al responsable del tratamiento.</p>

  <h2>Naturaleza de los datos</h2>
  <p>Los datos recogidos son tu nombre y las respuestas al cuestionario de autoevaluación, así como el resultado calculado (perfil por área, rasgos de comportamiento e índice de sinceridad de las respuestas).</p>
</div>
</body>
</html>
PRIV_EOF

echo "==> Escribiendo public/etica.html"
sudo tee "$PROJECT_DIR/public/etica.html" > /dev/null <<'ETICA_EOF'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Recomendaciones éticas para la empresa</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@700;800&family=Manrope:wght@400;500;600&display=swap" rel="stylesheet">
<style>
  :root{ --bg:#1c1e22; --accent:#FF9500; --accent2:#FFB347; --glass:rgba(255,255,255,0.055);
    --glass-border:rgba(255,255,255,0.10); --text:#f4f4f5; --text-dim:#9aa0a8; --warn:#e05a4e; }
  *{box-sizing:border-box;margin:0;padding:0;}
  body{font-family:'Manrope',system-ui,sans-serif;background:radial-gradient(circle at 12% 8%, rgba(255,149,0,0.10), transparent 40%), var(--bg);
    color:var(--text);padding:40px 20px;display:flex;justify-content:center;}
  .card{max-width:680px;background:var(--glass);border:1px solid var(--glass-border);border-radius:20px;padding:36px;}
  h1{font-family:'Outfit',sans-serif;font-weight:800;font-size:1.5rem;margin-bottom:18px;}
  h2{font-family:'Outfit',sans-serif;font-weight:700;font-size:1rem;margin:22px 0 8px;color:var(--accent);}
  p,li{color:var(--text-dim);font-size:.92rem;line-height:1.6;}
  ul{margin-left:20px;margin-top:6px;}
  strong{color:var(--text);}
  .warn-box{border:1px solid rgba(224,90,78,0.3);background:rgba(224,90,78,0.08);border-radius:14px;padding:16px 18px;margin:18px 0;}
  .warn-box p{color:var(--text);}
</style>
</head>
<body>
<div class="card">
  <h1>Recomendaciones éticas para la empresa</h1>

  <div class="warn-box">
    <p><strong>No se recomienda usar este test como único filtro para decidir la contratación de un candidato/a.</strong></p>
  </div>

  <h2>Qué es realmente este test</h2>
  <p>Es una <strong>guía orientativa</strong> con dos utilidades:</p>
  <ul>
    <li>Ayudar a identificar <strong>qué puesto se ajusta mejor</strong> al perfil declarado por el candidato/a.</li>
    <li>Dar una <strong>orientación sobre la confianza</strong> que merece ese resultado, a través del índice de sinceridad/fiabilidad.</li>
  </ul>

  <h2>Por qué no es un factor determinante</h2>
  <p>Es un cuestionario de <strong>autoinforme</strong>, no un instrumento psicométrico validado clínicamente. Su resultado debe tratarse como <strong>un factor estadístico más, no decisivo</strong>, dentro de un proceso de selección.</p>
  <p>Además, personas con formación en psicología o simplemente familiarizadas con este tipo de cuestionarios pueden identificar qué se está midiendo y <strong>responder de forma estratégica</strong>, superando el test con facilidad sin que el resultado refleje fielmente su perfil real. El índice de sinceridad reduce este riesgo, pero no lo elimina por completo.</p>

  <h2>Uso recomendado</h2>
  <ul>
    <li>Combinar siempre el resultado con una <strong>entrevista personal</strong>.</li>
    <li>Contrastarlo con una <strong>prueba técnica</strong> cuando el puesto lo requiera.</li>
    <li>Apoyarse en un <strong>periodo de prueba</strong> como validación real del encaje.</li>
    <li>No descartar ni priorizar automáticamente a un candidato/a basándose solo en este resultado.</li>
  </ul>
</div>
</body>
</html>
ETICA_EOF

echo "==> Construyendo imagen Docker"
sudo docker build -t "$IMAGE_NAME" "$PROJECT_DIR"

echo "==> Eliminando contenedor previo si existe"
sudo docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

echo "==> Levantando contenedor en el puerto $PORT (datos persistentes en $PROJECT_DIR/data)"
sudo docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p "$PORT:80" \
  -v "$PROJECT_DIR/data:/app/data" \
  -e ADMIN_USER="$ADMIN_USER" \
  -e ADMIN_PASSWORD="$ADMIN_PASSWORD" \
  "$IMAGE_NAME"

echo "==> Listo."
echo "    Test:  http://$(hostname -I | awk '{print $1}'):$PORT"
echo "    Panel: http://$(hostname -I | awk '{print $1}'):$PORT/tests  (usuario: $ADMIN_USER)"
