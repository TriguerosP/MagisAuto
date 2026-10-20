'use strict';

const $ = (sel, raiz = document) => raiz.querySelector(sel);
const $$ = (sel, raiz = document) => [...raiz.querySelectorAll(sel)];
let contadorIds = 0;
const nuevoId = prefijo => `${prefijo}${++contadorIds}`;

function qs(params) {
  if (!params) return '';
  const u = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (v !== null && v !== undefined && v !== '') u.append(k, v);
  }
  const s = u.toString();
  return s ? '?' + s : '';
}

async function api(metodo, ruta, cuerpo) {
  const opciones = { method: metodo, headers: {} };
  if (cuerpo !== undefined) {
    opciones.headers['Content-Type'] = 'application/json';
    opciones.body = JSON.stringify(cuerpo);
  }
  let respuesta;
  try {
    respuesta = await fetch('/api' + ruta, opciones);
  } catch {
    throw new Error('No se pudo conectar con la API. Verifique que el proyecto esté en ejecución.');
  }
  let datos = null;
  try { datos = await respuesta.json(); } catch {   }
  if (!respuesta.ok) throw new Error(datos?.mensaje || `La API respondió con el error ${respuesta.status}.`);
  return datos?.tablas ?? [];
}

const get = (ruta, params) => api('GET', ruta + qs(params));
const primera = tablas => (tablas && tablas[0] && tablas[0][0]) || null;

const cache = {};
async function catalogo(ruta) {
  if (!cache[ruta]) cache[ruta] = (await get(ruta))[0] ?? [];
  return cache[ruta];
}
async function parametros() {
  const filas = await catalogo('/parametros');
  return Object.fromEntries(filas.map(f => [f.Codigo, Number(f.Valor)]));
}

const esc = v => String(v ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const fQ = new Intl.NumberFormat('es-GT', { style: 'currency', currency: 'GTQ' });
const f2 = new Intl.NumberFormat('es-GT', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const fN = new Intl.NumberFormat('es-GT', { maximumFractionDigits: 4 });
const quetzales = n => fQ.format(Number(n) || 0);
const pad = n => String(n).padStart(2, '0');
const norm = s => String(s ?? '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();

function hoyISO(dias = 0, meses = 0) {
  const d = new Date();
  d.setMonth(d.getMonth() + meses);
  d.setDate(d.getDate() + dias);
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

function fecha(valor) {
  if (!valor) return '';
  const [d, t] = String(valor).split('T');
  const [a, m, dia] = d.split('-');
  let texto = `${dia}/${m}/${a}`;
  if (t && !t.startsWith('00:00:00')) texto += ' ' + t.slice(0, 5);
  return texto;
}

const PALABRAS = {
  Numero: 'número', Obligacion: 'obligación', Credito: 'crédito', Creditos: 'créditos', Telefono: 'teléfono',
  Telefonos: 'teléfonos', Direccion: 'dirección', Anio: 'año', Vehiculo: 'vehículo', Vehiculos: 'vehículos',
  Interes: 'interés', Region: 'región', Linea: 'línea', Cancelacion: 'cancelación', Aprobacion: 'aprobación',
  Codigo: 'código', Comision: 'comisión', Depreciacion: 'depreciación', Recaudacion: 'recaudación', Dias: 'días',
  Mas: 'más', Calificacion: 'calificación', Descripcion: 'descripción', Ultimo: 'último', Garantia: 'garantía',
  Modificacion: 'modificación', Asignacion: 'asignación', Proyeccion: 'proyección', Indice: 'índice',
  Patrimonial: 'patrimonial', Pct: '%'
};

function etiqueta(clave) {
  const partes = String(clave)
    .replace(/([a-záéíóúñ0-9])([A-Z])/g, '$1 $2')
    .replace(/([A-Z]+)([A-Z][a-z])/g, '$1 $2')
    .split(' ');
  return partes.map((p, i) => {
    let w = PALABRAS[p] ?? p;
    if (/^[A-Z]{2,}$/.test(w)) return w;
    w = w.toLowerCase();
    return i === 0 ? w.charAt(0).toUpperCase() + w.slice(1) : w;
  }).join(' ');
}

const RX_PCT = /Porcentaje|Pct|Tasa/;
const RX_CONTEO = /^(Cuotas|Creditos|Transacciones|Pagos|Abonos|Clientes|Vendedores|Referencias|Direcciones|Fiadores|Vehiculos|Dias|Plazo|Vencidas|Pagadas)/;
const RX_CRUDO = /(Id$|^Anio$|^Mes$|^Dia$|^Numero|^Codigo|^Orden$|^Ranking$|^Posicion$|Edad)/;
const RX_DINERO = /Monto|Total|Saldo|Valor|Precio|Costo|Capital|Interes|Comision|Cartera|Recaud|Sobrecosto|Perdida|PagaDeMas|Enganche|Seguro|Manejo|CuotaNivelada|CuotaMensual|Pagado|Financiado|Esperado|Vencido|Ventas|Promedio|Base/;

function tipoColumna(clave, valor) {
  if (typeof valor === 'boolean') return 'bool';
  if (typeof valor === 'string' && /^\d{4}-\d{2}-\d{2}T/.test(valor)) return 'fecha';
  if (typeof valor !== 'number') return 'texto';
  if (RX_PCT.test(clave)) return 'pct';
  if (RX_CONTEO.test(clave) && !/Total|Monto/.test(clave)) return 'entero';
  if (RX_CRUDO.test(clave)) return 'crudo';
  if (RX_DINERO.test(clave)) return 'dinero';
  return 'numero';
}

const ESTADOS = {
  ACTIVO: 'ok', PAGADA: 'ok', DISPONIBLE: 'ok', EXCELENTE: 'ok', ELIMINADO: 'ok', ACTUALIZADO: 'ok',
  CANCELADO: 'info', 'EN GARANTIA': 'info', BUENO: 'info',
  PENDIENTE: 'aviso', PARCIAL: 'aviso', REGULAR: 'aviso', DESACTIVADO: 'aviso',
  DEFICIENTE: 'alerta', ANULADO: 'apagado'
};
function etiquetaEstado(v) {
  if (v === 'EN GARANTIA') return 'En garantía';
  const s = String(v).toLowerCase();
  return s.charAt(0).toUpperCase() + s.slice(1);
}
const insignia = v => `<span class="insignia ${ESTADOS[v] ?? ''}">${esc(etiquetaEstado(v))}</span>`;

function celda(tipo, v, clave) {
  if (v === null || v === undefined || v === '') return '<span class="vacio">—</span>';
  switch (tipo) {
    case 'dinero': return quetzales(v);
    case 'pct': return f2.format(v) + ' %';
    case 'entero':
      if (clave === 'DiasAtraso' && v > 0) return `<span class="texto-alerta">${fN.format(v)}</span>`;
      return fN.format(v);
    case 'numero': return fN.format(v);
    case 'crudo': return esc(v);
    case 'fecha': return fecha(v);
    case 'bool': return v ? '<span class="insignia ok">Sí</span>' : '<span class="insignia">No</span>';
    default:
      if (/Estado|Calificacion|Resultado/.test(clave) && ESTADOS[v]) return insignia(v);
      return esc(v);
  }
}
const alinear = tipo => (['dinero', 'pct', 'entero', 'numero'].includes(tipo) ? 'num' : '');

const dato = (etq, valor) => `<div><dt>${esc(etq)}</dt><dd>${esc(valor ?? '—')}</dd></div>`;
const datoHTML = (etq, html) => `<div><dt>${esc(etq)}</dt><dd>${html}</dd></div>`;

function tabla(contenedor, filas, opc = {}) {
  if (!filas || !filas.length) {
    contenedor.innerHTML = `<p class="vacio-tabla">${esc(opc.vacio ?? 'No hay registros que mostrar.')}</p>`;
    contenedor.onclick = null;
    return;
  }
  const ocultar = opc.ocultar ?? [];
  const cols = opc.columnas ?? Object.keys(filas[0]).filter(c => !ocultar.includes(c)).map(c => ({ c }));
  const valorDe = (col, f) => (col.v ? col.v(f) : f[col.c]);
  const tipos = cols.map(col => {
    if (col.tipo) return col.tipo;
    if (opc.tipos?.[col.c]) return opc.tipos[col.c];
    const ejemplo = filas.map(f => valorDe(col, f)).find(x => x !== null && x !== undefined);
    return tipoColumna(col.c, ejemplo);
  });

  const cab = cols.map((col, i) => `<th class="${alinear(tipos[i])}" scope="col">${esc(col.t ?? etiqueta(col.c))}</th>`).join('')
    + (opc.acciones ? '<th class="acc"><span class="sr">Acciones</span></th>' : '');

  const cuerpo = filas.map((f, fi) => {
    const clase = opc.claseFila ? opc.claseFila(f) : '';
    const tds = cols.map((col, i) => {
      const valor = valorDe(col, f);
      const html = col.html ? col.html(f) : celda(tipos[i], valor, col.c);
      const largo = typeof valor === 'string' && valor.length > 45 ? ' largo' : '';
      return `<td class="${alinear(tipos[i])}${largo}">${html}</td>`;
    }).join('');
    const acciones = opc.acciones
      ? `<td class="acc">${opc.acciones(f).map(a => `<button type="button" class="btn-tabla ${a.clase ?? ''}" data-acc="${a.acc}" data-fila="${fi}">${esc(a.texto)}</button>`).join('')}</td>`
      : '';
    return `<tr${clase ? ` class="${clase}"` : ''}>${tds}${acciones}</tr>`;
  }).join('');

  let pie = '';
  if (opc.totales?.length) {
    const tds = cols.map((col, i) => {
      if (i === 0) return '<td>Total</td>';
      if (!opc.totales.includes(col.c)) return '<td></td>';
      const suma = filas.reduce((s, f) => s + (Number(valorDe(col, f)) || 0), 0);
      return `<td class="num">${celda(tipos[i], Math.round(suma * 100) / 100, col.c)}</td>`;
    }).join('');
    pie = `<tfoot><tr>${tds}${opc.acciones ? '<td></td>' : ''}</tr></tfoot>`;
  }

  contenedor.innerHTML = `<div class="tabla-envoltura"><table class="tabla"><thead><tr>${cab}</tr></thead><tbody>${cuerpo}</tbody>${pie}</table></div>`;
  contenedor.onclick = opc.alAccion
    ? e => {
        const b = e.target.closest('[data-acc]');
        if (b && contenedor.contains(b)) opc.alAccion(b.dataset.acc, filas[Number(b.dataset.fila)], b);
      }
    : null;
}

function modal({ titulo, contenido = '', tam = 'md', pie = '' }) {
  const d = document.createElement('dialog');
  d.className = `modal modal-${tam}`;
  d.innerHTML = `<div class="modal-marco">
      <header class="modal-enc"><h2></h2><button type="button" class="cerrar" aria-label="Cerrar">×</button></header>
      <div class="modal-cuerpo"></div>
      <footer class="modal-pie"></footer>
    </div>`;
  $('h2', d).textContent = titulo;
  $('.modal-cuerpo', d).innerHTML = contenido;
  $('.modal-pie', d).innerHTML = pie;
  d.addEventListener('click', e => { if (e.target.closest('.cerrar, [data-cerrar]')) d.close(); });
  d.addEventListener('close', () => {
    const pendientes = $$('.avisos-modal .aviso', d);
    d.remove();
    pendientes.forEach(a => contenedorAvisos().append(a));
  });
  document.body.appendChild(d);
  d.showModal();
  return {
    d,
    cuerpo: $('.modal-cuerpo', d),
    pie: $('.modal-pie', d),
    titulo: t => { $('h2', d).textContent = t; },
    cerrar: () => d.close()
  };
}

function confirmar(texto, boton = 'Eliminar') {
  return new Promise(resolver => {
    const m = modal({
      titulo: 'Confirmar',
      contenido: `<p>${esc(texto)}</p>`,
      pie: `<button type="button" class="btn btn-sec" data-cerrar>Cancelar</button><button type="button" class="btn btn-peligro" data-si>${esc(boton)}</button>`
    });
    let ok = false;
    $('[data-si]', m.d).onclick = () => { ok = true; m.cerrar(); };
    m.d.addEventListener('close', () => resolver(ok));
  });
}

function contenedorAvisos() {
  const abierta = $$('dialog[open]').pop();
  if (!abierta) return $('#avisos');
  let c = $('.avisos-modal', abierta);
  if (!c) {
    c = document.createElement('div');
    c.className = 'avisos-modal';
    c.setAttribute('aria-live', 'polite');
    abierta.append(c);
  }
  return c;
}

function aviso(texto, tipo = 'ok') {
  const a = document.createElement('div');
  a.className = `aviso aviso-${tipo}`;
  a.textContent = texto;
  contenedorAvisos().append(a);
  setTimeout(() => a.remove(), tipo === 'error' ? 8000 : 4500);
}

function imprimir(html) {
  const zona = $('#impresion');
  zona.innerHTML = html;
  document.body.classList.add('imprimiendo');
  const fin = () => {
    document.body.classList.remove('imprimiendo');
    zona.innerHTML = '';
    window.removeEventListener('afterprint', fin);
  };
  window.addEventListener('afterprint', fin);
  window.print();
}

function debounce(fn, ms) {
  let t;
  return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms); };
}

const cargando = '<p class="cargando">Cargando…</p>';

async function opcionesDe(fuente) {
  const filas = (await get(fuente.ruta, fuente.params))[0] ?? [];
  return filas.map(f => [f[fuente.v], typeof fuente.t === 'function' ? fuente.t(f) : f[fuente.t]]);
}

async function camposHTML(campos, valores = {}, modo = 'nuevo') {
  const partes = [];
  for (const c of campos) {
    if (c.soloNuevo && modo !== 'nuevo') continue;
    if (c.soloEditar && modo !== 'editar') continue;
    const id = nuevoId('c_');
    let v = valores[c.n];
    if (v === undefined || v === null) v = c.def !== undefined ? (typeof c.def === 'function' ? c.def() : c.def) : '';
    if (c.t === 'date' && typeof v === 'string') v = v.slice(0, 10);
    const req = c.req ? ' required' : '';
    const etq = esc(c.l ?? etiqueta(c.n));
    const ayuda = c.ayuda ? `<small>${esc(c.ayuda)}</small>` : '';
    const ancho = c.ancho ? ' campo-ancho' : '';

    if (c.t === 'check') {
      const marcado = v === true || v === 1 || v === '1' || v === 'true';
      partes.push(`<div class="campo campo-check${ancho}"><input type="checkbox" id="${id}" name="${c.n}"${marcado ? ' checked' : ''}><label for="${id}">${etq}</label></div>`);
      continue;
    }

    let control;
    if (c.t === 'select') {
      const ops = c.opciones ?? await opcionesDe(c.fuente);
      const vacia = c.vacio === false ? '' : `<option value="">${esc(c.vacio ?? (c.req ? 'Seleccione…' : 'Todos'))}</option>`;
      control = `<select id="${id}" name="${c.n}"${req}>${vacia}${ops.map(([ov, ot]) =>
        `<option value="${esc(ov)}"${String(ov) === String(v) ? ' selected' : ''}>${esc(ot)}</option>`).join('')}</select>`;
    } else if (c.t === 'textarea') {
      control = `<textarea id="${id}" name="${c.n}" rows="3"${req}>${esc(v)}</textarea>`;
    } else {
      const tipo = c.t ?? 'text';
      const extra = [
        c.max ? ` maxlength="${c.max}"` : '',
        c.patron ? ` pattern="${c.patron}"` : '',
        c.paso ? ` step="${c.paso}"` : (tipo === 'number' ? ' step="any"' : ''),
        c.min !== undefined ? ` min="${c.min}"` : '',
        c.maxv !== undefined ? ` max="${c.maxv}"` : '',
        c.ph ? ` placeholder="${esc(c.ph)}"` : '',
        c.lista ? ` list="${c.lista}"` : ''
      ].join('');
      control = `<input id="${id}" name="${c.n}" type="${tipo}" value="${esc(v)}"${req}${extra}>`;
    }
    partes.push(`<div class="campo${ancho}"><label for="${id}">${etq}</label>${control}${ayuda}</div>`);
  }
  return `<div class="rejilla-campos">${partes.join('')}</div>`;
}

function leerCampos(raiz) {
  const datos = {};
  $$('input[name], select[name], textarea[name]', raiz).forEach(el => {
    if (el.type === 'radio') { if (el.checked) datos[el.name] = el.value; return; }
    datos[el.name] = el.type === 'checkbox' ? el.checked : el.value.trim();
  });
  return datos;
}

async function formularioModal({ titulo, campos, valores = {}, modo = 'nuevo', textoGuardar = 'Guardar', tam = 'md', previo = '', alGuardar }) {
  const idf = nuevoId('f');
  const m = modal({
    titulo, tam,
    contenido: `<form id="${idf}" class="formulario">${previo}${await camposHTML(campos, valores, modo)}<p class="error-form" hidden></p></form>`,
    pie: `<button type="button" class="btn btn-sec" data-cerrar>Cancelar</button><button type="submit" class="btn btn-pri" form="${idf}">${esc(textoGuardar)}</button>`
  });
  const form = $('#' + idf, m.d);
  form.onsubmit = async e => {
    e.preventDefault();
    const boton = $('[type="submit"]', m.d);
    const error = $('.error-form', form);
    error.hidden = true;
    boton.disabled = true;
    try {
      await alGuardar(leerCampos(form), m);
      m.cerrar();
    } catch (ex) {
      error.textContent = ex.message;
      error.hidden = false;
    } finally {
      boton.disabled = false;
    }
  };
  return m;
}

const icono = (nombre, clase = 'ic') => `<svg class="${clase}" aria-hidden="true"><use href="#i-${nombre}"/></svg>`;

const ICONO_PAGINA = {
  inicio: 'cuadros', clientes: 'cliente', fiadores: 'fiadores', vehiculos: 'auto', creditos: 'monedas',
  pagos: 'calendario', consultas: 'buscar', reportes: 'barras', catalogos: 'libro'
};
let iconoActual = 'cuadros';

function encabezado(titulo, descripcion, acciones = '') {
  return `<header class="pag-enc"><div class="pag-titulo">${icono(iconoActual, 'ic ic-titulo')}<div><h1>${esc(titulo)}</h1>${descripcion ? `<p>${esc(descripcion)}</p>` : ''}</div></div>`
    + `${acciones ? `<div class="pag-acciones">${acciones}</div>` : ''}</header>`;
}

const FUENTES = {
  agencias:        { ruta: '/agencias', v: 'AgenciaId', t: f => `${f.Nombre} (${f.Region})` },
  clientes:        { ruta: '/clientes', v: 'ClienteId', t: f => `${f.NombreCompleto}, código ${f.ClienteId}` },
  personas:        { ruta: '/personas', v: 'PersonaId', t: f => `${f.NombreCompleto}, DPI ${f.DPI}` },
  tipos:           { ruta: '/tipos-telefono', v: 'TipoTelefonoId', t: 'Descripcion' },
  referencias:     { ruta: '/referencias', v: 'ReferenciaId', t: f => `${f.NombreCompleto}, referencia de ${f.Cliente}` },
  vehiculos:       { ruta: '/vehiculos', v: 'VIN', t: f => `${f.Marca} ${f.Linea} ${f.Anio}, VIN ${f.VIN}` },
  marcas:          { ruta: '/marcas', v: 'MarcaId', t: f => `${f.Nombre} (${f.CodigoMarca})` },
  fiadores:        { ruta: '/fiadores/buscar', params: { Activo: 1 }, v: 'FiadorId', t: f => `${f.NombreCompleto}, DPI ${f.DPI}` },
  creditos:        { ruta: '/creditos', v: 'CreditoId', t: f => `${f.NumeroObligacion}, ${f.Cliente}` },
  creditosActivos: { ruta: '/creditos/buscar', params: { Estado: 'ACTIVO' }, v: 'CreditoId', t: f => `${f.NumeroObligacion}, ${f.Cliente}` },
  vendedores:      { ruta: '/vendedores/buscar', params: { Activo: 1 }, v: 'VendedorId', t: f => `${f.NombreCompleto} (${f.Agencia})` }
};
const SI_NO = [['1', 'Sí'], ['0', 'No']];

let contadorGraficas = 0;
function minigrafica(valores, titulo) {
  const v = (valores ?? []).map(Number).filter(Number.isFinite);
  if (v.length < 2 || v.every(x => x === 0)) return '';
  const w = 160, h = 56, m = 5;
  const min = Math.min(...v), max = Math.max(...v), rango = max - min || 1;
  const p = v.map((y, i) => [i / (v.length - 1) * w, m + (h - 2 * m) * (1 - (y - min) / rango)]);
  let d = `M${p[0][0].toFixed(1)} ${p[0][1].toFixed(1)}`;
  for (let i = 0; i < p.length - 1; i++) {
    const a = p[i - 1] ?? p[i], b = p[i], c = p[i + 1], e = p[i + 2] ?? c;
    const c1 = [b[0] + (c[0] - a[0]) / 6, b[1] + (c[1] - a[1]) / 6];
    const c2 = [c[0] - (e[0] - b[0]) / 6, c[1] - (e[1] - b[1]) / 6];
    d += ` C${c1[0].toFixed(1)} ${c1[1].toFixed(1)} ${c2[0].toFixed(1)} ${c2[1].toFixed(1)} ${c[0].toFixed(1)} ${c[1].toFixed(1)}`;
  }
  const id = 'mg' + (++contadorGraficas);
  return `<svg viewBox="0 0 ${w} ${h}" preserveAspectRatio="none" role="img" aria-label="${esc(titulo)}"><title>${esc(titulo)}</title>
    <defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1565D8" stop-opacity=".25"/><stop offset="1" stop-color="#1565D8" stop-opacity="0"/></linearGradient></defs>
    <path d="${d} L${w} ${h} L0 ${h} Z" fill="url(#${id})"/>
    <path d="${d}" fill="none" stroke="#1565D8" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" vector-effect="non-scaling-stroke"/></svg>`;
}

function minibarras(valores, titulo) {
  const v = (valores ?? []).map(x => Number(x) || 0);
  if (!v.length || v.every(x => x === 0)) return '';
  const w = 160, h = 56, ancho = 22, hueco = (w - ancho * v.length) / (v.length - 1 || 1), max = Math.max(...v);
  const colores = ['#F7D35A', '#F7A061', '#F07482', '#C8102E'];
  return `<svg viewBox="0 0 ${w} ${h}" role="img" aria-label="${esc(titulo)}"><title>${esc(titulo)}</title>${v.map((x, i) => {
    const alto = Math.max(3, x / max * (h - 4));
    return `<rect x="${(i * (ancho + hueco)).toFixed(1)}" y="${(h - alto).toFixed(1)}" width="${ancho}" height="${alto.toFixed(1)}" rx="4" fill="${colores[i % colores.length]}"/>`;
  }).join('')}</svg>`;
}

function cuadroIndicadores(k, s = {}) {
  if (!k) return '';
  const item = (etq, valor, nota, ic, esquina, grafica = '') =>
    `<div class="ind${grafica ? ' con-grafica' : ''}">
      <span class="ind-icono">${icono(ic)}</span>
      <span class="ind-valor" title="${esc(valor)}">${valor}</span>
      <span class="ind-esquina">${icono(esquina)}</span>
      <span class="ind-texto"><span class="ind-etq">${esc(etq)}</span>${nota ? `<span class="ind-nota">${esc(nota)}</span>` : ''}</span>
      ${grafica ? `<span class="ind-grafica">${grafica}</span>` : ''}
    </div>`;
  const mora = Number(k.IndiceMoraPct ?? 0);
  return `<div class="indicadores">
    ${item('Cartera por cobrar', quetzales(k.CarteraTotal), `${fN.format(k.CreditosActivos)} créditos activos`, 'hoja', 'tendencia',
           minigrafica(s.flujo, 'Cobro esperado por mes, próximos 12 meses'))}
    ${item('Cartera vencida', quetzales(k.CarteraVencida), `${fN.format(k.CreditosEnMora)} créditos en mora`, 'efectivo', 'reloj',
           minibarras(s.antiguedad, 'Cartera vencida por antigüedad: 1-30, 31-60, 61-90 y más de 90 días'))}
    ${item('Índice de mora', f2.format(mora) + ' %', 'Cartera vencida entre cartera por cobrar', 'porcentaje', 'barras')}
    ${item('Recaudado este mes', quetzales(k.RecaudacionMes), `Comisiones generadas: ${quetzales(k.ComisionesMes)}`, 'recaudo', 'monedas',
           minigrafica(s.recaudado, 'Recaudación de los últimos 6 meses'))}
    ${item('Colocado este mes', quetzales(k.MontoColocadoMes), `${fN.format(k.CreditosEmitidosMes)} créditos emitidos`, 'calendario', 'hoja',
           minigrafica(s.colocado, 'Monto financiado por mes, últimos 6 meses'))}
    ${item('Intereses por devengar', quetzales(k.InteresesPorDevengar), `${fN.format(k.ClientesActivos)} clientes activos`, 'fiadores', 'monedas',
           minigrafica(s.intereses, 'Intereses por mes, próximos 12 meses'))}
  </div>`;
}

function seriePorMes(filas, campoFecha, campoValor, n = 6) {
  const suma = {};
  (filas ?? []).forEach(f => {
    const mes = String(f[campoFecha] ?? '').slice(0, 7);
    if (mes) suma[mes] = (suma[mes] ?? 0) + (Number(f[campoValor]) || 0);
  });
  const hoy = new Date();
  return Array.from({ length: n }, (_, i) => {
    const d = new Date(hoy.getFullYear(), hoy.getMonth() - (n - 1 - i), 1);
    return suma[`${d.getFullYear()}-${pad(d.getMonth() + 1)}`] ?? 0;
  });
}

function barrasMora(filas) {
  const max = Math.max(1, ...filas.map(f => Number(f.MontoVencido) || 0));
  return `<div class="barras">${filas.map((f, i) => `
    <div class="barra-fila">
      <span class="barra-etq">${esc(f.Rango)}</span>
      <span class="barra-pista"><span class="barra b-mora-${i + 1}" style="width:${((Number(f.MontoVencido) || 0) / max * 100).toFixed(1)}%"></span></span>
      <span class="barra-valor">${quetzales(f.MontoVencido)}<small>${f.Creditos} ${f.Creditos === 1 ? 'crédito' : 'créditos'}, ${f2.format(f.PorcentajeDeCartera ?? 0)} % de la cartera</small></span>
    </div>`).join('')}</div>`;
}

async function pInicio() {
  const v = $('#vista');
  v.innerHTML = encabezado('Tablero', `Situación de la cartera al ${fecha(hoyISO())}.`,
      `<a class="btn btn-sec btn-grande" href="#/creditos/nuevo">${icono('nube')}Emitir crédito</a>`
      + `<a class="btn btn-pri btn-grande" href="#/pagos">${icono('mas')}Registrar pago</a>`)
    + '<section id="t-kpi" aria-label="Indicadores"></section>'
    + `<div class="dos-col">
         <section class="tarjeta"><div class="tarjeta-enc">${icono('reloj')}<h2>Antigüedad de la mora</h2></div><div id="t-mora"></div></section>
         <section class="tarjeta"><div class="tarjeta-enc">${icono('calendario')}<h2>Cuotas que vencen en los próximos 7 días</h2></div><div id="t-vencer"></div></section>
       </div>`;

  const opcional = p => p.catch(() => null);
  const inicioMes = atras => { const d = new Date(); d.setDate(1); d.setMonth(d.getMonth() - atras); return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-01`; };
  const [r22, r13, r21, r10, r18, r01] = await Promise.all([
    get('/reportes/22'), get('/reportes/13'), get('/reportes/21', { Dias: 7 }),
    opcional(get('/reportes/10')),
    opcional(get('/reportes/18', { Desde: inicioMes(5), Hasta: hoyISO() })),
    opcional(get('/reportes/1', { Desde: inicioMes(5), Hasta: hoyISO() }))
  ]);
  const proyeccion = r10?.[0] ?? [];
  const series = {
    flujo: proyeccion.map(f => f.TotalEsperado),
    intereses: proyeccion.map(f => f.Intereses),
    antiguedad: (r13[0] ?? []).map(f => f.MontoVencido),
    recaudado: r18 ? seriePorMes((r18[0] ?? []).filter(f => String(f.MedioPago).startsWith('***')), 'Fecha', 'Total') : null,
    colocado: r01 ? seriePorMes(r01[0], 'FechaAprobacion', 'MontoFinanciado') : null
  };
  $('#t-kpi').innerHTML = cuadroIndicadores(primera(r22), series);
  $('#t-mora').innerHTML = barrasMora(r13[0] ?? []);
  tabla($('#t-vencer'), r21[0], {
    vacio: 'Ninguna cuota vence en los próximos 7 días.',
    columnas: [
      { c: 'FechaVencimiento', t: 'Vence' },
      { c: 'Cliente' },
      { c: 'NumeroObligacion', t: 'Crédito' },
      { c: 'NumeroCuota', t: 'Cuota' },
      { c: 'SaldoCuota', t: 'Por cobrar' },
      { c: 'Telefonos', t: 'Teléfono' }
    ]
  });
}

const CFG_CLIENTES = {
  ruta: '/clientes', id: 'ClienteId', titulo: 'Clientes', singular: 'cliente', referencias: true,
  desc: ''
};
const CFG_FIADORES = {
  ruta: '/fiadores', id: 'FiadorId', titulo: 'Fiadores', singular: 'fiador', referencias: false,
};
const CAMPOS_PERSONA = [
  { n: 'DPI', l: 'DPI (CUI)', req: true, max: 13, patron: '\\d{13}', ayuda: '13 dígitos, sin espacios' },
  { n: 'NIT', req: true, max: 15, patron: '[0-9Kk]+', ayuda: 'Sin guion' },
  { n: 'Nombres', req: true, max: 80 },
  { n: 'Apellidos', req: true, max: 80 },
  { n: 'FechaNacimiento', l: 'Fecha de nacimiento', t: 'date', req: true },
  { n: 'Correo', l: 'Correo electrónico', t: 'email', req: true, max: 120 }
];

const selectTipos = (tipos, sel = 1) =>
  `<select class="r-tipo" aria-label="Tipo de teléfono">${tipos.map(t => `<option value="${t.TipoTelefonoId}"${t.TipoTelefonoId === sel ? ' selected' : ''}>${esc(t.Descripcion)}</option>`).join('')}</select>`;
const inputsTelefono = () =>
  '<input class="r-numero" placeholder="Número" required pattern="[0-9+ \\-]{8,15}" maxlength="15" aria-label="Número de teléfono">';
const inputsDireccion = () =>
  '<input class="r-direccion" placeholder="Dirección" required maxlength="200" aria-label="Dirección">'
  + '<input class="r-municipio" placeholder="Municipio" required maxlength="60" aria-label="Municipio">'
  + '<input class="r-departamento" placeholder="Departamento" required maxlength="40" aria-label="Departamento">';

const PLANTILLAS = {
  tel: tipos => `<div class="repetible fila-tel">${selectTipos(tipos)}${inputsTelefono()}<button type="button" class="btn-quitar" data-quitar aria-label="Quitar teléfono">×</button></div>`,
  dir: () => `<div class="repetible fila-dir">${inputsDireccion()}<button type="button" class="btn-quitar" data-quitar aria-label="Quitar dirección">×</button></div>`,
  ref: (tipos, n) => `<div class="repetible bloque-ref">
      <div class="bloque-ref-enc"><strong>Referencia ${n}</strong><button type="button" class="btn-quitar" data-quitar aria-label="Quitar referencia ${n}">×</button></div>
      <div class="rejilla-campos">
        <label class="campo"><span>Nombre completo</span><input class="r-nombre" required maxlength="160"></label>
        <label class="campo"><span>Parentesco o relación</span><input class="r-parentesco" required maxlength="40" list="lista-parentescos"></label>
        <label class="campo"><span>Lugar de trabajo</span><input class="r-trabajo" maxlength="120"></label>
      </div>
      <div class="fila-tel">${selectTipos(tipos)}${inputsTelefono()}</div>
      <div class="fila-dir">${inputsDireccion()}</div>
    </div>`
};

const leerTelefono = fila => ({ TipoTelefonoId: $('.r-tipo', fila).value, Numero: $('.r-numero', fila).value.trim() });
const leerDireccion = fila => ({
  Direccion: $('.r-direccion', fila).value.trim(),
  Municipio: $('.r-municipio', fila).value.trim(),
  Departamento: $('.r-departamento', fila).value.trim()
});

async function pPersonas(cfg, args) {
  const v = $('#vista');
  const minRef = (await parametros()).MIN_REFERENCIAS ?? 3;
  v.innerHTML = encabezado(cfg.titulo, cfg.desc, `<button type="button" class="btn btn-pri" id="p-nuevo">Registrar ${cfg.singular}</button>`)
    + `<form class="filtros" id="p-filtros">
         <div class="campo"><label for="p-q">Buscar</label><input id="p-q" placeholder="Nombre, DPI o NIT"></div>
         <div class="campo"><label for="p-act">Estado</label><select id="p-act"><option value="">Todos</option><option value="1" selected>Activos</option><option value="0">Inactivos</option></select></div>
         <div class="filtros-botones"><button class="btn btn-sec">Buscar</button></div>
       </form>
       <div id="p-lista">${cargando}</div>`;

  const cargar = async () => {
    const q = $('#p-q').value.trim();
    const p = { Activo: $('#p-act').value };
    if (/^\d{13}$/.test(q)) p.DPI = q;
    else if (/^\d+[Kk]?$/.test(q)) p.NIT = q;
    else p.Nombre = q;
    const filas = (await get(cfg.ruta + '/buscar', p))[0];
    const columnas = [
      { c: cfg.id, t: 'Código' },
      { c: 'NombreCompleto', t: 'Nombre' },
      { c: 'DPI' }, { c: 'NIT' },
      { c: 'Telefonos', t: 'Teléfonos' }
    ];
    if (cfg.referencias) {
      columnas.push(
        { c: 'Referencias', html: f => (f.Referencias < minRef ? `<span class="insignia alerta">${f.Referencias} de ${minRef}</span>` : fN.format(f.Referencias)) },
        { c: 'CreditosActivos', t: 'Créditos activos' });
    } else {
      columnas.push({ c: 'CreditosRespaldados', t: 'Créditos respaldados' });
    }
    columnas.push({ c: 'Activo' });
    tabla($('#p-lista'), filas, {
      columnas,
      vacio: `No hay ${cfg.titulo.toLowerCase()} con ese criterio.`,
      acciones: () => [{ acc: 'ver', texto: 'Abrir ficha' }],
      alAccion: (a, f) => fichaPersona(cfg, f[cfg.id], cargar)
    });
  };

  $('#p-filtros').onsubmit = e => { e.preventDefault(); cargar().catch(ex => aviso(ex.message, 'error')); };
  $('#p-nuevo').onclick = () => nuevaPersona(cfg, cargar).catch(ex => aviso(ex.message, 'error'));
  await cargar();
  if (args?.[0]) fichaPersona(cfg, args[0], cargar);
}

async function nuevaPersona(cfg, alTerminar) {
  const tipos = await catalogo('/tipos-telefono');
  const minRef = (await parametros()).MIN_REFERENCIAS ?? 3;
  const idf = nuevoId('f');
  const m = modal({
    titulo: `Registrar ${cfg.singular}`, tam: 'lg',
    contenido: `<form id="${idf}" class="formulario">
        <fieldset><legend>Datos personales</legend>${await camposHTML(CAMPOS_PERSONA)}</fieldset>
        <fieldset><legend>Teléfonos</legend><div class="repetibles" data-rep="tel"></div><button type="button" class="btn-enlace" data-agregar="tel">Agregar otro teléfono</button></fieldset>
        <fieldset><legend>Direcciones</legend><div class="repetibles" data-rep="dir"></div><button type="button" class="btn-enlace" data-agregar="dir">Agregar otra dirección</button></fieldset>
        ${cfg.referencias ? `<fieldset><legend>Referencias personales</legend>
          <p class="nota">El departamento de cobros exige al menos ${minRef}. Cada referencia necesita su teléfono y su dirección para localizar al cliente en caso de atraso.</p>
          <div class="repetibles" data-rep="ref"></div><button type="button" class="btn-enlace" data-agregar="ref">Agregar otra referencia</button></fieldset>` : ''}
        <p class="error-form" hidden></p>
      </form>`,
    pie: `<button type="button" class="btn btn-sec" data-cerrar>Cancelar</button><button type="submit" class="btn btn-pri" form="${idf}">Registrar ${cfg.singular}</button>`
  });
  const form = $('#' + idf, m.d);
  const agregar = tipo => {
    const cont = $(`[data-rep="${tipo}"]`, form);
    cont.insertAdjacentHTML('beforeend', PLANTILLAS[tipo](tipos, cont.children.length + 1));
  };
  form.addEventListener('click', e => {
    const b = e.target.closest('[data-agregar]');
    if (b) agregar(b.dataset.agregar);
    const q = e.target.closest('[data-quitar]');
    if (q) q.closest('.repetible').remove();
  });
  agregar('tel');
  agregar('dir');
  if (cfg.referencias) for (let i = 0; i < minRef; i++) agregar('ref');

  form.onsubmit = async e => {
    e.preventDefault();
    const error = $('.error-form', form);
    const boton = $('[type="submit"]', m.d);
    const falla = texto => { error.textContent = texto; error.hidden = false; };
    error.hidden = true;

    const datos = leerCampos(form);
    const tels = $$('[data-rep="tel"] > .fila-tel', form).map(leerTelefono);
    const dirs = $$('[data-rep="dir"] > .fila-dir', form).map(leerDireccion);
    const refs = $$('.bloque-ref', form).map(b => ({
      NombreCompleto: $('.r-nombre', b).value.trim(),
      Parentesco: $('.r-parentesco', b).value.trim(),
      LugarTrabajo: $('.r-trabajo', b).value.trim(),
      tel: leerTelefono($('.fila-tel', b)),
      dir: leerDireccion($('.fila-dir', b))
    }));
    if (!tels.length) return falla('Registre al menos un teléfono.');
    if (!dirs.length) return falla('Registre al menos una dirección.');
    if (cfg.referencias && refs.length < minRef) return falla(`Registre al menos ${minRef} referencias personales.`);

    boton.disabled = true;
    let persona;
    try {
      persona = primera(await api('POST', cfg.ruta, datos));
    } catch (ex) {
      boton.disabled = false;
      return falla(ex.message);
    }
    try {
      for (const t of tels) await api('POST', '/telefonos-persona', { PersonaId: persona.PersonaId, ...t });
      for (const d of dirs) await api('POST', '/direcciones-persona', { PersonaId: persona.PersonaId, ...d });
      for (const r of refs) {
        const ref = primera(await api('POST', '/referencias', {
          ClienteId: persona.ClienteId, NombreCompleto: r.NombreCompleto, LugarTrabajo: r.LugarTrabajo, Parentesco: r.Parentesco
        }));
        await api('POST', '/telefonos-referencia', { ReferenciaId: ref.ReferenciaId, ...r.tel });
        await api('POST', '/direcciones-referencia', { ReferenciaId: ref.ReferenciaId, ...r.dir });
      }
      aviso(`${persona.NombreCompleto} quedó registrado con el código ${persona[cfg.id]}.`);
      m.cerrar();
      await alTerminar();
    } catch (ex) {
      aviso(`Se registró a ${persona.NombreCompleto}, pero falló un dato de contacto: ${ex.message} Complételo en su ficha.`, 'error');
      m.cerrar();
      await alTerminar();
      fichaPersona(cfg, persona[cfg.id], alTerminar);
    }
  };
}

async function fichaPersona(cfg, id, alCambiar) {
  const m = modal({ titulo: `Ficha del ${cfg.singular}`, tam: 'lg', contenido: cargando });
  m.cuerpo.addEventListener('click', e => { if (e.target.closest('a[href^="#/"]')) m.cerrar(); });
  const tipos = await catalogo('/tipos-telefono');
  const minRef = (await parametros()).MIN_REFERENCIAS ?? 3;

  const pintar = async () => {
    const p = primera(await get(cfg.ruta + '/buscar', { [cfg.id]: id }));
    if (!p) { m.cuerpo.innerHTML = '<p>Este registro ya no existe.</p>'; return; }
    m.titulo(p.NombreCompleto);

    const [tels, dirs, refs, creds] = await Promise.all([
      get('/telefonos-persona/buscar', { PersonaId: p.PersonaId }),
      get('/direcciones-persona/buscar', { PersonaId: p.PersonaId }),
      cfg.referencias ? get('/referencias/buscar', { ClienteId: id }) : Promise.resolve([[]]),
      cfg.referencias ? get('/creditos/buscar', { ClienteId: id }) : get('/creditos-fiadores/buscar', { FiadorId: id })
    ]);
    const refsActivas = (refs[0] ?? []).filter(r => r.Activo).length;

    m.cuerpo.innerHTML = `
      <div class="ficha-enc">
        <dl class="datos">
          ${dato('Código', p[cfg.id])}${dato('DPI', p.DPI)}${dato('NIT', p.NIT)}
          ${dato('Fecha de nacimiento', fecha(p.FechaNacimiento))}${dato('Correo', p.Correo)}
          ${datoHTML('Estado', p.Activo ? insignia('ACTIVO') : '<span class="insignia">Inactivo</span>')}
        </dl>
        <div class="ficha-acciones">
          <button type="button" class="btn btn-sec" data-a="editar">Editar datos</button>
          ${cfg.referencias ? `<a class="btn btn-sec" href="#/reportes/6?ClienteId=${id}">Estado de cuenta</a>` : ''}
          <button type="button" class="btn btn-peligro" data-a="eliminar">Eliminar</button>
        </div>
      </div>
      <section class="ficha-sec"><h3>Teléfonos</h3><div data-s="tels"></div>
        <form class="agregar-linea" data-f="tel">${selectTipos(tipos)}${inputsTelefono()}<button class="btn btn-sec">Agregar teléfono</button></form>
      </section>
      <section class="ficha-sec"><h3>Direcciones</h3><div data-s="dirs"></div>
        <form class="agregar-linea" data-f="dir">${inputsDireccion()}<button class="btn btn-sec">Agregar dirección</button></form>
      </section>
      ${cfg.referencias ? `<section class="ficha-sec"><h3>Referencias personales <span class="contador">${refsActivas} registradas, mínimo ${minRef}</span></h3>
        <div data-s="refs"></div><button type="button" class="btn-enlace" data-a="nueva-ref">Agregar referencia</button></section>` : ''}
      <section class="ficha-sec"><h3>${cfg.referencias ? 'Créditos' : 'Créditos que respalda'}</h3><div data-s="creds"></div></section>`;

    tabla($('[data-s="tels"]', m.cuerpo), tels[0], {
      vacio: 'Sin teléfonos registrados.',
      columnas: [{ c: 'TipoTelefono', t: 'Tipo' }, { c: 'Numero', t: 'Número' }],
      acciones: () => [{ acc: 'quitar', texto: 'Quitar', clase: 'peligro' }],
      alAccion: async (a, f) => {
        if (!await confirmar(`¿Quitar el teléfono ${f.Numero}?`, 'Quitar')) return;
        await ejecutarYRepintar(() => api('DELETE', `/telefonos-persona/${f.TelefonoPersonaId}`));
      }
    });
    tabla($('[data-s="dirs"]', m.cuerpo), dirs[0], {
      vacio: 'Sin direcciones registradas.',
      columnas: [{ c: 'Direccion', t: 'Dirección' }, { c: 'Municipio' }, { c: 'Departamento' }],
      acciones: () => [{ acc: 'quitar', texto: 'Quitar', clase: 'peligro' }],
      alAccion: async (a, f) => {
        if (!await confirmar('¿Quitar esta dirección?', 'Quitar')) return;
        await ejecutarYRepintar(() => api('DELETE', `/direcciones-persona/${f.DireccionPersonaId}`));
      }
    });
    if (cfg.referencias) {
      tabla($('[data-s="refs"]', m.cuerpo), refs[0], {
        vacio: 'Sin referencias registradas.',
        columnas: [{ c: 'NombreCompleto', t: 'Nombre' }, { c: 'Parentesco' }, { c: 'LugarTrabajo', t: 'Trabajo' }, { c: 'Telefonos', t: 'Teléfonos' }, { c: 'Direcciones' }],
        acciones: () => [
          { acc: 'editar', texto: 'Editar' },
          { acc: 'tel', texto: 'Teléfono' },
          { acc: 'dir', texto: 'Dirección' },
          { acc: 'quitar', texto: 'Quitar', clase: 'peligro' }
        ],
        alAccion: (a, f) => accionReferencia(a, f, pintar)
      });
      tabla($('[data-s="creds"]', m.cuerpo), creds[0], {
        vacio: 'Este cliente aún no tiene créditos.',
        columnas: [
          { c: 'NumeroObligacion', t: 'Crédito' },
          { c: 'Vehiculo', t: 'Vehículo', v: f => `${f.Marca} ${f.Linea} ${f.Anio}` },
          { c: 'FechaAprobacion', t: 'Aprobado' },
          { c: 'MontoFinanciado' }, { c: 'SaldoPendiente' }, { c: 'DiasAtraso', t: 'Días de atraso' }, { c: 'Estado' }
        ],
        acciones: () => [{ acc: 'abrir', texto: 'Abrir' }],
        alAccion: (a, f) => fichaCredito(f.CreditoId, pintar)
      });
    } else {
      tabla($('[data-s="creds"]', m.cuerpo), creds[0], {
        vacio: 'No respalda ningún crédito.',
        columnas: [{ c: 'NumeroObligacion', t: 'Crédito' }, { c: 'Cliente' }, { c: 'EstadoCredito', t: 'Estado' }, { c: 'FechaAsignacion', t: 'Asignado' }],
        acciones: () => [{ acc: 'abrir', texto: 'Abrir' }],
        alAccion: (a, f) => fichaCredito(f.CreditoId, pintar)
      });
    }

    $('[data-f="tel"]', m.cuerpo).onsubmit = e => {
      e.preventDefault();
      ejecutarYRepintar(() => api('POST', '/telefonos-persona', { PersonaId: p.PersonaId, ...leerTelefono(e.target) }));
    };
    $('[data-f="dir"]', m.cuerpo).onsubmit = e => {
      e.preventDefault();
      ejecutarYRepintar(() => api('POST', '/direcciones-persona', { PersonaId: p.PersonaId, ...leerDireccion(e.target) }));
    };
    m.cuerpo.onclick = async e => {
      const b = e.target.closest('[data-a]');
      if (!b) return;
      if (b.dataset.a === 'editar') {
        formularioModal({
          titulo: 'Editar datos', modo: 'editar', valores: p,
          campos: [...CAMPOS_PERSONA, { n: 'Activo', t: 'check', l: `${cfg.singular.charAt(0).toUpperCase() + cfg.singular.slice(1)} activo` }],
          alGuardar: async d => {
            await api('PUT', `${cfg.ruta}/${id}`, d);
            aviso('Datos actualizados.');
            await pintar();
            alCambiar?.();
          }
        });
      }
      if (b.dataset.a === 'eliminar') {
        if (!await confirmar(`¿Eliminar a ${p.NombreCompleto}? Si tiene créditos, solo se desactivará para conservar el historial.`)) return;
        try {
          const r = primera(await api('DELETE', `${cfg.ruta}/${id}`));
          aviso(r?.Mensaje ?? 'Registro eliminado.');
          m.cerrar();
          alCambiar?.();
        } catch (ex) { aviso(ex.message, 'error'); }
      }
      if (b.dataset.a === 'nueva-ref') nuevaReferencia(id, pintar);
    };
  };

  const ejecutarYRepintar = async accion => {
    try { await accion(); await pintar(); alCambiar?.(); }
    catch (ex) { aviso(ex.message, 'error'); }
  };

  try { await pintar(); }
  catch (ex) { m.cuerpo.innerHTML = `<p class="error-bloque">${esc(ex.message)}</p>`; }
}

async function nuevaReferencia(clienteId, alTerminar) {
  const tipos = await catalogo('/tipos-telefono');
  const idf = nuevoId('f');
  const m = modal({
    titulo: 'Agregar referencia personal', tam: 'lg',
    contenido: `<form id="${idf}" class="formulario">${PLANTILLAS.ref(tipos, '').replace('data-quitar', 'hidden')}<p class="error-form" hidden></p></form>`,
    pie: `<button type="button" class="btn btn-sec" data-cerrar>Cancelar</button><button type="submit" class="btn btn-pri" form="${idf}">Agregar referencia</button>`
  });
  const form = $('#' + idf, m.d);
  form.onsubmit = async e => {
    e.preventDefault();
    try {
      const b = $('.bloque-ref', form);
      const ref = primera(await api('POST', '/referencias', {
        ClienteId: clienteId,
        NombreCompleto: $('.r-nombre', b).value.trim(),
        Parentesco: $('.r-parentesco', b).value.trim(),
        LugarTrabajo: $('.r-trabajo', b).value.trim()
      }));
      await api('POST', '/telefonos-referencia', { ReferenciaId: ref.ReferenciaId, ...leerTelefono($('.fila-tel', b)) });
      await api('POST', '/direcciones-referencia', { ReferenciaId: ref.ReferenciaId, ...leerDireccion($('.fila-dir', b)) });
      aviso('Referencia agregada.');
      m.cerrar();
      await alTerminar();
    } catch (ex) {
      const err = $('.error-form', form);
      err.textContent = ex.message;
      err.hidden = false;
    }
  };
}

async function accionReferencia(accion, f, alTerminar) {
  try {
    if (accion === 'editar') {
      await formularioModal({
        titulo: 'Editar referencia', modo: 'editar', valores: f,
        campos: [
          { n: 'NombreCompleto', l: 'Nombre completo', req: true, max: 160 },
          { n: 'Parentesco', l: 'Parentesco o relación', req: true, max: 40, lista: 'lista-parentescos' },
          { n: 'LugarTrabajo', l: 'Lugar de trabajo', max: 120 }
        ],
        alGuardar: async d => { await api('PUT', `/referencias/${f.ReferenciaId}`, d); aviso('Referencia actualizada.'); await alTerminar(); }
      });
    }
    if (accion === 'tel') {
      await formularioModal({
        titulo: `Teléfono de ${f.NombreCompleto}`,
        campos: [
          { n: 'TipoTelefonoId', l: 'Tipo', t: 'select', req: true, fuente: FUENTES.tipos, vacio: false },
          { n: 'Numero', l: 'Número', req: true, max: 15, patron: '[0-9+ \\-]{8,15}' }
        ],
        textoGuardar: 'Agregar teléfono',
        alGuardar: async d => { await api('POST', '/telefonos-referencia', { ReferenciaId: f.ReferenciaId, ...d }); aviso('Teléfono agregado.'); await alTerminar(); }
      });
    }
    if (accion === 'dir') {
      await formularioModal({
        titulo: `Dirección de ${f.NombreCompleto}`,
        campos: [
          { n: 'Direccion', l: 'Dirección', req: true, max: 200, ancho: true },
          { n: 'Municipio', req: true, max: 60 },
          { n: 'Departamento', req: true, max: 40 }
        ],
        textoGuardar: 'Agregar dirección',
        alGuardar: async d => { await api('POST', '/direcciones-referencia', { ReferenciaId: f.ReferenciaId, ...d }); aviso('Dirección agregada.'); await alTerminar(); }
      });
    }
    if (accion === 'quitar') {
      if (!await confirmar(`¿Quitar la referencia ${f.NombreCompleto}?`, 'Quitar')) return;
      await api('DELETE', `/referencias/${f.ReferenciaId}`);
      aviso('Referencia quitada.');
      await alTerminar();
    }
  } catch (ex) { aviso(ex.message, 'error'); }
}

const CAMPOS_VEHICULO = [
  { n: 'VIN', l: 'VIN (número de chasis)', req: true, max: 17, patron: '[A-HJ-NPR-Za-hj-npr-z0-9]{17}', ayuda: '17 caracteres; nunca lleva I, O ni Q', soloNuevo: true },
  { n: 'MarcaId', l: 'Marca', t: 'select', req: true, fuente: FUENTES.marcas },
  { n: 'Linea', l: 'Línea o modelo comercial', req: true, max: 60 },
  { n: 'Anio', l: 'Año de fabricación', t: 'number', req: true, min: 1990, maxv: 2100, paso: 1 },
  { n: 'Color', max: 30 },
  { n: 'ValorAgencia', l: 'Valor de agencia, precio de contado (Q)', t: 'number', req: true, min: 1, paso: '0.01' },
  { n: 'Placa', max: 10, ayuda: 'Déjela vacía si el vehículo aún no tiene placa' }
];

async function pVehiculos() {
  const v = $('#vista');
  v.innerHTML = encabezado('Vehículos en garantía', '',
      '<button type="button" class="btn btn-pri" id="v-nuevo">Registrar vehículo</button>')
    + `<form class="filtros" id="v-f">
         <div class="campo"><label for="v-q">Buscar</label><input id="v-q" placeholder="VIN, placa o línea"></div>
         ${(await camposHTML([{ n: 'MarcaId', l: 'Marca', t: 'select', fuente: FUENTES.marcas }])).replace('<div class="rejilla-campos">', '').replace(/<\/div>$/, '')}
         <div class="campo campo-check"><input type="checkbox" id="v-disp" name="SoloDisponibles"><label for="v-disp">Solo disponibles</label></div>
         <div class="filtros-botones"><button class="btn btn-sec">Buscar</button></div>
       </form><div id="v-lista">${cargando}</div>`;

  const cargar = async () => {
    const q = $('#v-q').value.trim();
    const p = { MarcaId: $('#v-f [name="MarcaId"]').value, SoloDisponibles: $('#v-disp').checked ? 1 : '' };
    if (/^P?\d{3}[A-Z]{3}$/i.test(q)) p.Placa = q;
    else if (/\d/.test(q) && /^[A-Z0-9]{5,17}$/i.test(q)) p.VIN = q;
    else p.Linea = q;
    const filas = (await get('/vehiculos/buscar', p))[0];
    tabla($('#v-lista'), filas, {
      vacio: 'No hay vehículos con ese criterio.',
      columnas: [{ c: 'VIN' }, { c: 'Marca' }, { c: 'Linea', t: 'Línea' }, { c: 'Anio', t: 'Año' }, { c: 'Color' }, { c: 'Placa' },
                 { c: 'ValorAgencia', t: 'Valor de agencia' }, { c: 'EstadoGarantia', t: 'Estado' }, { c: 'CreditoActivo', t: 'Crédito activo' }],
      acciones: () => [{ acc: 'editar', texto: 'Editar' }, { acc: 'historial', texto: 'Historial de valor' }, { acc: 'eliminar', texto: 'Eliminar', clase: 'peligro' }],
      alAccion: (a, f) => accionVehiculo(a, f, cargar)
    });
  };
  $('#v-f').onsubmit = e => { e.preventDefault(); cargar().catch(ex => aviso(ex.message, 'error')); };
  $('#v-nuevo').onclick = () => formularioModal({
    titulo: 'Registrar vehículo', campos: CAMPOS_VEHICULO, textoGuardar: 'Registrar vehículo',
    alGuardar: async d => {
      const r = primera(await api('POST', '/vehiculos', d));
      aviso(`Vehículo ${r.Marca} ${r.Linea} registrado.`);
      await cargar();
    }
  });
  await cargar();
}

async function accionVehiculo(accion, f, recargar) {
  try {
    if (accion === 'editar') {
      await formularioModal({
        titulo: `Editar ${f.Marca} ${f.Linea}`, campos: CAMPOS_VEHICULO, valores: f, modo: 'editar',
        previo: `<p class="nota">VIN ${esc(f.VIN)}. El valor de agencia no puede cambiar si el vehículo ya respaldó un crédito.</p>`,
        alGuardar: async d => { await api('PUT', `/vehiculos/${encodeURIComponent(f.VIN)}`, d); aviso('Vehículo actualizado.'); await recargar(); }
      });
    }
    if (accion === 'eliminar') {
      if (!await confirmar(`¿Eliminar el vehículo ${f.Marca} ${f.Linea}, VIN ${f.VIN}?`)) return;
      const r = primera(await api('DELETE', `/vehiculos/${encodeURIComponent(f.VIN)}`));
      aviso(r?.Mensaje ?? 'Vehículo eliminado.');
      await recargar();
    }
    if (accion === 'historial') historialValor(f);
  } catch (ex) { aviso(ex.message, 'error'); }
}

async function historialValor(veh) {
  const m = modal({ titulo: `Historial de valor: ${veh.Marca} ${veh.Linea} ${veh.Anio}`, tam: 'lg', contenido: cargando });
  const pintar = async () => {
    const filas = (await get('/historial-valor/buscar', { VIN: veh.VIN }))[0];
    m.cuerpo.innerHTML = `<p class="nota">Registra cómo pierde valor la garantía desde que sale de la agencia. Valor de agencia: ${quetzales(veh.ValorAgencia)}.</p>
      <div data-s="hist"></div>
      <h3 class="ficha-sec">Registrar nueva valuación</h3>
      <form class="formulario" data-f="val">${await camposHTML([
        { n: 'Fecha', t: 'date', req: true, def: () => hoyISO() },
        { n: 'ValorEstimado', l: 'Valor estimado (Q)', t: 'number', req: true, min: 0, maxv: veh.ValorAgencia, paso: '0.01' },
        { n: 'Concepto', req: true, max: 100, ph: 'Por ejemplo: avalúo anual' }
      ])}<div class="acciones-form"><button class="btn btn-sec">Registrar valuación</button></div></form>`;
    tabla($('[data-s="hist"]', m.cuerpo), filas, {
      columnas: [{ c: 'Fecha' }, { c: 'ValorEstimado', t: 'Valor estimado' }, { c: 'PerdidaValor', t: 'Pérdida de valor' },
                 { c: 'PorcentajeDepreciacion', t: 'Depreciación acumulada' }, { c: 'Concepto' }],
      acciones: () => [{ acc: 'quitar', texto: 'Quitar', clase: 'peligro' }],
      alAccion: async (a, f) => {
        if (!await confirmar('¿Quitar esta valuación?', 'Quitar')) return;
        try { await api('DELETE', `/historial-valor/${f.HistorialValorId}`); await pintar(); } catch (ex) { aviso(ex.message, 'error'); }
      }
    });
    $('[data-f="val"]', m.cuerpo).onsubmit = async e => {
      e.preventDefault();
      try {
        await api('POST', '/historial-valor', { VIN: veh.VIN, ...leerCampos(e.target) });
        aviso('Valuación registrada.');
        await pintar();
      } catch (ex) { aviso(ex.message, 'error'); }
    };
  };
  try { await pintar(); } catch (ex) { m.cuerpo.innerHTML = `<p class="error-bloque">${esc(ex.message)}</p>`; }
}

function panelCostoReal(r) {
  if (!r) return '';
  const max = Math.max(Number(r.CostoTotalDelVehiculo), Number(r.PrecioContado), 1);
  const barra = (etq, valor, clase) => `<div class="cr-fila">
      <span class="cr-etq"><span>${etq}</span><span class="cr-monto">${quetzales(valor)}</span></span>
      <span class="cr-pista"><span class="cr-barra ${clase}" style="width:${(Number(valor) / max * 100).toFixed(1)}%"></span></span>
    </div>`;
  return `<div class="cr">
      <div class="cr-cuota"><span class="cr-cuota-valor">${quetzales(r.CuotaMensualTotal)}</span><span>al mes durante ${r.PlazoMeses} meses</span></div>
      <dl class="cr-desglose">${dato('Capital e interés', quetzales(r.CuotaNivelada))}${dato('Manejo y seguros', quetzales(Number(r.CuotaMensualTotal) - Number(r.CuotaNivelada)))}</dl>
      ${barra('Precio de contado', r.PrecioContado, 'cr-precio')}
      ${barra('Lo que pagará en total', r.CostoTotalDelVehiculo, 'cr-total')}
      ${barra('Valor del auto al terminar', r.ValorEstimadoAlTerminar, 'cr-final')}
      <p class="cr-de-mas">Pagará <strong>${quetzales(r.PagaDeMas)}</strong> más que el precio de contado (${f2.format(r.PorcentajeDeMas)} %): ${quetzales(r.TotalIntereses)} de intereses y ${quetzales(Number(r.TotalSeguros) + Number(r.TotalManejoCuenta))} de seguros y manejo de cuenta.</p>
      <p class="cr-conclusion">${esc(r.Conclusion)}</p>
    </div>`;
}

async function pCreditos(args) {
  const v = $('#vista');
  v.innerHTML = encabezado('Créditos', '',
      '<button type="button" class="btn btn-pri" id="cr-nuevo">Emitir crédito</button>')
    + `<form class="filtros" id="cr-f">
         <div class="campo"><label for="cr-q">Buscar</label><input id="cr-q" placeholder="Número de obligación o cliente"></div>
         <div class="campo"><label for="cr-e">Estado</label><select id="cr-e" name="Estado"><option value="">Todos</option><option value="ACTIVO" selected>Activos</option><option value="CANCELADO">Cancelados</option></select></div>
         <div class="campo"><label for="cr-d">Aprobados desde</label><input type="date" id="cr-d" name="Desde"></div>
         <div class="campo"><label for="cr-h">Hasta</label><input type="date" id="cr-h" name="Hasta"></div>
         <div class="campo campo-check"><input type="checkbox" id="cr-a" name="ConAtraso"><label for="cr-a">Solo con atraso</label></div>
         <div class="filtros-botones"><button class="btn btn-sec">Buscar</button></div>
       </form><div id="cr-lista">${cargando}</div>`;

  const cargar = async () => {
    const p = leerCampos($('#cr-f'));
    p.ConAtraso = p.ConAtraso ? 1 : '';
    const q = $('#cr-q').value.trim();
    if (/^(MA-?)?\d+$/i.test(q)) p.NumeroObligacion = q.toUpperCase();
    else p.Cliente = q;
    const filas = (await get('/creditos/buscar', p))[0];
    tabla($('#cr-lista'), filas, {
      vacio: 'No hay créditos con ese criterio.',
      columnas: [
        { c: 'NumeroObligacion', t: 'Crédito' },
        { c: 'Cliente' },
        { c: 'Vehiculo', t: 'Vehículo', v: f => `${f.Marca} ${f.Linea} ${f.Anio}` },
        { c: 'FechaAprobacion', t: 'Aprobado' },
        { c: 'MontoFinanciado' },
        { c: 'CuotaMensualTotal', t: 'Cuota mensual' },
        { c: 'Avance', t: 'Cuotas pagadas', v: f => `${f.CuotasPagadas} de ${f.PlazoMeses}` },
        { c: 'SaldoPendiente' },
        { c: 'DiasAtraso', t: 'Atraso', html: f => (f.Estado !== 'ACTIVO' ? '<span class="vacio">—</span>' : f.DiasAtraso > 0 ? `<span class="texto-alerta">${f.DiasAtraso} días</span>` : 'Al día') },
        { c: 'Estado' }
      ],
      claseFila: f => (f.Estado === 'ACTIVO' && f.DiasAtraso > 0 ? 'fila-atraso' : ''),
      acciones: () => [{ acc: 'abrir', texto: 'Abrir' }],
      alAccion: (a, f) => fichaCredito(f.CreditoId, cargar)
    });
  };
  $('#cr-f').onsubmit = e => { e.preventDefault(); cargar().catch(ex => aviso(ex.message, 'error')); };
  $('#cr-nuevo').onclick = () => emitirCredito(cargar).catch(ex => aviso(ex.message, 'error'));
  await cargar();
  if (args?.[0] === 'nuevo') emitirCredito(cargar).catch(ex => aviso(ex.message, 'error'));
  else if (args?.[0]) fichaCredito(args[0], cargar);
}

async function emitirCredito(alTerminar) {
  const [clientes, vehiculos, vendedores, fiadores, prm] = await Promise.all([
    get('/clientes/buscar', { Activo: 1 }),
    get('/vehiculos/buscar', { SoloDisponibles: 1 }),
    get('/vendedores/buscar', { Activo: 1 }),
    get('/fiadores/buscar', { Activo: 1 }),
    parametros()
  ]);
  const lc = clientes[0] ?? [], lv = vehiculos[0] ?? [], lven = vendedores[0] ?? [], lf = fiadores[0] ?? [];
  const minRef = prm.MIN_REFERENCIAS ?? 3;
  const idf = nuevoId('f');

  const m = modal({
    titulo: 'Emitir crédito', tam: 'xl',
    contenido: `<div class="emision">
      <form id="${idf}" class="formulario">
        <fieldset><legend>Solicitante y garantía</legend><div class="rejilla-campos">
          <div class="campo campo-ancho"><label for="${idf}-c">Cliente</label>
            <select id="${idf}-c" name="ClienteId" required><option value="">Seleccione…</option>
            ${lc.map(c => `<option value="${c.ClienteId}">${esc(c.NombreCompleto)}, DPI ${esc(c.DPI)}</option>`).join('')}</select></div>
          <p class="aviso-campo" data-aviso-cliente hidden></p>
          <div class="campo campo-ancho"><label for="${idf}-v">Vehículo que queda en garantía</label>
            <select id="${idf}-v" name="VIN" required><option value="">Seleccione…</option>
            ${lv.map(x => `<option value="${x.VIN}">${esc(x.Marca)} ${esc(x.Linea)} ${x.Anio}, ${quetzales(x.ValorAgencia)}, VIN ${x.VIN}</option>`).join('')}</select></div>
          ${lv.length ? '' : '<p class="aviso-campo">No hay vehículos disponibles. Registre uno en Vehículos en garantía.</p>'}
          <div class="campo"><label for="${idf}-ve">Vendedor responsable</label>
            <select id="${idf}-ve" name="VendedorId" required><option value="">Seleccione…</option>
            ${lven.map(x => `<option value="${x.VendedorId}">${esc(x.NombreCompleto)} (${esc(x.Agencia)})</option>`).join('')}</select></div>
          <div class="campo"><label for="${idf}-f">Fecha de aprobación</label><input type="date" id="${idf}-f" name="FechaAprobacion" value="${hoyISO()}" required></div>
        </div></fieldset>
        <fieldset><legend>Condiciones</legend><div class="rejilla-campos">
          <div class="campo"><label for="${idf}-e">Enganche (Q)</label><input type="number" id="${idf}-e" name="Enganche" min="0" step="0.01" required><small>Pagado directamente en la agencia.</small></div>
          <div class="campo"><label for="${idf}-p">Plazo en meses</label><input type="number" id="${idf}-p" name="PlazoMeses" min="1" max="120" step="1" value="${prm.PLAZO_MESES ?? 60}" required></div>
          <div class="campo"><label for="${idf}-co">Comisión del vendedor (%)</label><input type="number" id="${idf}-co" name="PorcentajeComision" min="0" max="100" step="0.01" value="${prm.COMISION_VENDEDOR ?? 1.5}" required><small>Se paga sobre cada pago efectivo del cliente.</small></div>
          <div class="campo"><span class="etq">Tasa de interés anual</span><span class="valor-fijo">${f2.format(prm.TASA_INTERES_ANUAL ?? 0)} % sobre saldos</span><small>Parámetro vigente; se cambia en Catálogos.</small></div>
        </div></fieldset>
        <fieldset><legend>Fiadores</legend>
          <p class="nota">Asígnelos cuando el comité de riesgos determine riesgo moderado o alto.</p>
          <div class="lista-checks">${lf.map(f => `<label class="check" data-persona="${f.PersonaId}"><input type="checkbox" value="${f.FiadorId}"> <span>${esc(f.NombreCompleto)} <small>DPI ${esc(f.DPI)}</small></span></label>`).join('') || '<p class="nota">No hay fiadores registrados.</p>'}</div>
        </fieldset>
        <p class="error-form" hidden></p>
      </form>
      <aside class="costo-real" data-costo aria-live="polite"><h3>Costo real del crédito</h3><p class="nota">Elija el vehículo y escriba el enganche para ver cuánto pagará el cliente.</p></aside>
    </div>`,
    pie: `<button type="button" class="btn btn-sec" data-cerrar>Cancelar</button><button type="submit" class="btn btn-pri" form="${idf}">Emitir crédito</button>`
  });

  const form = $('#' + idf, m.d);
  const el = form.elements;
  const panel = $('[data-costo]', m.d);
  const boton = $('[type="submit"]', m.d);
  const avisoCliente = $('[data-aviso-cliente]', form);
  const placeholder = texto => `<h3>Costo real del crédito</h3><p class="nota">${esc(texto)}</p>`;

  el.ClienteId.onchange = () => {
    const c = lc.find(x => String(x.ClienteId) === el.ClienteId.value);
    const faltan = c && c.Referencias < minRef;
    avisoCliente.hidden = !faltan;
    avisoCliente.innerHTML = faltan
      ? `Este cliente tiene ${c.Referencias} ${c.Referencias === 1 ? 'referencia' : 'referencias'} y se exigen ${minRef}. <a href="#/clientes/${c.ClienteId}">Complételas en su ficha</a>.`
      : '';
    boton.disabled = Boolean(faltan);
    $$('.check', form).forEach(ch => {
      const mismo = c && ch.dataset.persona === String(c.PersonaId);
      ch.classList.toggle('deshabilitado', Boolean(mismo));
      $('input', ch).disabled = Boolean(mismo);
      if (mismo) $('input', ch).checked = false;
    });
  };
  avisoCliente.addEventListener('click', e => { if (e.target.closest('a')) m.cerrar(); });

  const simular = debounce(async () => {
    const veh = lv.find(x => x.VIN === el.VIN.value);
    const eng = parseFloat(el.Enganche.value);
    const plazo = parseInt(el.PlazoMeses.value, 10);
    if (!veh || Number.isNaN(eng)) { panel.innerHTML = placeholder('Elija el vehículo y escriba el enganche para ver cuánto pagará el cliente.'); return; }
    if (eng < 0 || eng >= veh.ValorAgencia) { panel.innerHTML = placeholder('El enganche debe ser menor al precio de contado del vehículo.'); return; }
    if (!(plazo >= 1 && plazo <= 120)) { panel.innerHTML = placeholder('El plazo debe estar entre 1 y 120 meses.'); return; }
    try {
      const r = primera(await get('/reportes/24', { PrecioContado: veh.ValorAgencia, Enganche: eng, PlazoMeses: plazo }));
      panel.innerHTML = '<h3>Costo real del crédito</h3>' + panelCostoReal(r);
    } catch (ex) { panel.innerHTML = placeholder(ex.message); }
  }, 350);

  el.VIN.onchange = () => {
    const veh = lv.find(x => x.VIN === el.VIN.value);
    if (veh && !el.Enganche.value) el.Enganche.value = (Math.round(veh.ValorAgencia * 0.2 * 100) / 100).toFixed(2);
    simular();
  };
  el.Enganche.oninput = simular;
  el.PlazoMeses.oninput = simular;

  form.onsubmit = async e => {
    e.preventDefault();
    const error = $('.error-form', form);
    error.hidden = true;
    const datos = leerCampos(form);
    datos.Fiadores = $$('.lista-checks input:checked', form).map(i => i.value).join(',') || null;
    boton.disabled = true;
    try {
      const cr = primera(await api('POST', '/creditos', datos));
      aviso(`Crédito ${cr.NumeroObligacion} emitido: ${cr.PlazoMeses} cuotas de ${quetzales(cr.CuotaMensualTotal)}.`);
      m.cerrar();
      await alTerminar?.();
      fichaCredito(cr.CreditoId, alTerminar);
    } catch (ex) {
      error.textContent = ex.message;
      error.hidden = false;
    } finally {
      boton.disabled = false;
    }
  };
}

async function fichaCredito(id, alCambiar) {
  const m = modal({ titulo: 'Crédito', tam: 'xl', contenido: cargando });
  m.cuerpo.addEventListener('click', e => { if (e.target.closest('a[href^="#/"]')) m.cerrar(); });

  const pintar = async () => {
    const [cred, plan, fiad, pagos] = await Promise.all([
      get('/creditos/buscar', { CreditoId: id }),
      get('/reportes/7', { CreditoId: id }),
      get('/creditos-fiadores/buscar', { CreditoId: id }),
      get('/pagos/buscar', { CreditoId: id, IncluirAnulados: 1 })
    ]);
    const c = primera(cred);
    if (!c) { m.cuerpo.innerHTML = '<p>Este crédito ya no existe.</p>'; return; }
    m.titulo(`Crédito ${c.NumeroObligacion}`);
    const sinPagos = (pagos[0] ?? []).length === 0;
    const editable = c.Estado === 'ACTIVO' && sinPagos;
    const ind = (etq, valor, clase = '') => `<div class="ind ${clase}"><span class="ind-valor">${valor}</span><span class="ind-etq">${esc(etq)}</span></div>`;

    m.cuerpo.innerHTML = `
      <div class="ficha-enc">
        <div>
          <p class="ficha-sub">${insignia(c.Estado)} <span>${esc(c.Cliente)}, DPI ${esc(c.DPI)}</span></p>
          <dl class="datos">
            ${dato('Vehículo', `${c.Marca} ${c.Linea} ${c.Anio}`)}${dato('VIN', c.VIN)}${dato('Placa', c.Placa ?? 'Sin placa')}
            ${dato('Vendedor', `${c.Vendedor} (${c.Agencia})`)}${dato('Fecha de aprobación', fecha(c.FechaAprobacion))}
            ${dato('Plazo', `${c.PlazoMeses} meses`)}${dato('Tasa anual', `${f2.format(c.TasaInteresAnual)} % sobre saldos`)}
            ${dato('Comisión del vendedor', `${f2.format(c.PorcentajeComision)} % de cada pago`)}${dato('Fiadores', c.Fiadores)}
          </dl>
        </div>
        <div class="ficha-acciones">
          ${c.Estado === 'ACTIVO' ? `<a class="btn btn-pri" href="#/pagos/${id}">Registrar pago</a>` : ''}
          <button type="button" class="btn btn-sec" data-a="imprimir">Imprimir plan de pagos</button>
          ${editable ? '<button type="button" class="btn btn-sec" data-a="editar">Editar condiciones</button><button type="button" class="btn btn-peligro" data-a="eliminar">Eliminar</button>' : ''}
        </div>
      </div>
      <div class="indicadores indicadores-compactos">
        ${ind('Precio de contado', quetzales(c.PrecioContado))}
        ${ind('Enganche', quetzales(c.Enganche))}
        ${ind('Monto financiado', quetzales(c.MontoFinanciado))}
        ${ind('Cuota mensual', quetzales(c.CuotaMensualTotal))}
        ${ind('Intereses a generar', quetzales(c.TotalIntereses))}
        ${ind('Total recaudable', quetzales(c.TotalRecaudable))}
        ${ind('Pagado', quetzales(c.TotalPagado))}
        ${ind('Saldo pendiente', quetzales(c.SaldoPendiente))}
        ${ind('Cuotas pagadas', `${c.CuotasPagadas} de ${c.PlazoMeses}`)}
        ${ind('Días de atraso', c.Estado === 'ACTIVO' ? fN.format(c.DiasAtraso) : '—', c.DiasAtraso > 0 && c.Estado === 'ACTIVO' ? 'alerta' : '')}
      </div>
      <section class="ficha-sec"><h3>Fiadores</h3><div data-s="fiad"></div>
        ${c.Estado === 'ACTIVO' ? `<form class="agregar-linea" data-f="fiador">${(await camposHTML([{ n: 'FiadorId', l: 'Fiador', t: 'select', req: true, fuente: FUENTES.fiadores }])).replace('<div class="rejilla-campos">', '').replace(/<\/div>$/, '')}<button class="btn btn-sec">Asignar fiador</button></form>` : ''}
      </section>
      <section class="ficha-sec"><h3>Plan de pagos</h3><div data-s="plan" class="desplazable"></div></section>
      <section class="ficha-sec"><h3>Pagos recibidos</h3><div data-s="pagos"></div></section>`;

    tabla($('[data-s="fiad"]', m.cuerpo), fiad[0], {
      vacio: 'Este crédito está respaldado solo por la prenda del vehículo.',
      columnas: [{ c: 'Fiador' }, { c: 'DPIFiador', t: 'DPI' }, { c: 'TelefonosFiador', t: 'Teléfonos' }, { c: 'CorreoFiador', t: 'Correo' }, { c: 'FechaAsignacion', t: 'Asignado' }],
      acciones: () => (c.Estado === 'ACTIVO' ? [{ acc: 'quitar', texto: 'Retirar', clase: 'peligro' }] : []),
      alAccion: async (a, f) => {
        if (!await confirmar(`¿Retirar a ${f.Fiador} como fiador de este crédito?`, 'Retirar')) return;
        await ejecutarYRepintar(() => api('DELETE', `/creditos-fiadores/${id}${qs({ FiadorId: f.FiadorId })}`));
      }
    });
    const columnasPlan = [
      { c: 'NumeroCuota', t: 'Cuota' }, { c: 'FechaVencimiento', t: 'Vence' }, { c: 'SaldoInicial', t: 'Saldo inicial' },
      { c: 'Interes', t: 'Interés' }, { c: 'Capital' }, { c: 'ManejoCuenta', t: 'Manejo' }, { c: 'SeguroAuto', t: 'Seguro auto' },
      { c: 'SeguroVida', t: 'Seguro vida' }, { c: 'TotalCuota', t: 'Total cuota' }, { c: 'MontoPagado', t: 'Pagado' },
      { c: 'Estado' }, { c: 'DiasAtraso', t: 'Atraso' }
    ];
    tabla($('[data-s="plan"]', m.cuerpo), plan[1], {
      columnas: columnasPlan,
      claseFila: f => (f.DiasAtraso > 0 ? 'fila-atraso' : ''),
      totales: ['Interes', 'Capital', 'ManejoCuenta', 'SeguroAuto', 'SeguroVida', 'TotalCuota', 'MontoPagado']
    });
    tabla($('[data-s="pagos"]', m.cuerpo), pagos[0], {
      vacio: 'Aún no se han recibido pagos.',
      columnas: [{ c: 'NumeroRecibo', t: 'Recibo' }, { c: 'FechaHora', t: 'Fecha' }, { c: 'NumeroCuota', t: 'Cuota' },
                 { c: 'MedioPago', t: 'Medio de pago' }, { c: 'ReferenciaBancaria', t: 'Referencia' }, { c: 'Monto' },
                 { c: 'ComisionVendedor', t: 'Comisión' },
                 { c: 'Anulada', t: 'Estado', html: f => (f.Anulada ? insignia('ANULADO') : insignia('ACTIVO')) }],
      acciones: f => [{ acc: 'recibo', texto: 'Recibo' }, ...(f.Anulada ? [] : [{ acc: 'anular', texto: 'Anular', clase: 'peligro' }])],
      alAccion: async (a, f) => {
        if (a === 'recibo') verRecibo(f);
        if (a === 'anular') {
          if (!await confirmar(`¿Anular el recibo ${f.NumeroRecibo} por ${quetzales(f.Monto)}? El saldo vuelve a la cuota ${f.NumeroCuota}.`, 'Anular')) return;
          await ejecutarYRepintar(() => api('DELETE', `/pagos/${f.TransaccionId}`));
        }
      }
    });

    const formFiador = $('[data-f="fiador"]', m.cuerpo);
    if (formFiador) {
      formFiador.onsubmit = e => {
        e.preventDefault();
        ejecutarYRepintar(() => api('POST', '/creditos-fiadores', { CreditoId: id, FiadorId: leerCampos(formFiador).FiadorId }));
      };
    }

    m.cuerpo.onclick = async e => {
      const b = e.target.closest('[data-a]');
      if (!b) return;
      if (b.dataset.a === 'imprimir') {
        imprimir(`<h1>Plan de pagos del crédito ${esc(c.NumeroObligacion)}</h1>
          <p>${esc(c.Cliente)}, DPI ${esc(c.DPI)}. ${esc(c.Marca)} ${esc(c.Linea)} ${c.Anio}, VIN ${esc(c.VIN)}.</p>
          <p>Monto financiado ${quetzales(c.MontoFinanciado)} a ${c.PlazoMeses} meses, tasa ${f2.format(c.TasaInteresAnual)} % anual sobre saldos.
             Intereses a generar ${quetzales(c.TotalIntereses)}; total recaudable ${quetzales(c.TotalRecaudable)}.</p>
          ${$('[data-s="plan"]', m.cuerpo).innerHTML}`);
      }
      if (b.dataset.a === 'editar') {
        formularioModal({
          titulo: `Editar condiciones de ${c.NumeroObligacion}`, modo: 'editar', valores: c,
          previo: '<p class="nota">Al guardar se vuelve a generar el plan de pagos completo. Solo es posible mientras el crédito no tenga pagos.</p>',
          campos: [
            { n: 'VendedorId', l: 'Vendedor', t: 'select', req: true, fuente: FUENTES.vendedores },
            { n: 'Enganche', l: 'Enganche (Q)', t: 'number', req: true, min: 0, paso: '0.01' },
            { n: 'PlazoMeses', l: 'Plazo en meses', t: 'number', req: true, min: 1, maxv: 120, paso: 1 },
            { n: 'PorcentajeComision', l: 'Comisión del vendedor (%)', t: 'number', req: true, min: 0, maxv: 100, paso: '0.01' }
          ],
          alGuardar: async d => { await api('PUT', `/creditos/${id}`, d); aviso('Condiciones actualizadas y plan regenerado.'); await pintar(); alCambiar?.(); }
        });
      }
      if (b.dataset.a === 'eliminar') {
        if (!await confirmar(`¿Eliminar el crédito ${c.NumeroObligacion}? El vehículo quedará disponible.`)) return;
        try {
          const r = primera(await api('DELETE', `/creditos/${id}`));
          aviso(r?.Mensaje ?? 'Crédito eliminado.');
          m.cerrar();
          alCambiar?.();
        } catch (ex) { aviso(ex.message, 'error'); }
      }
    };
  };

  const ejecutarYRepintar = async accion => {
    try { await accion(); await pintar(); alCambiar?.(); }
    catch (ex) { aviso(ex.message, 'error'); }
  };

  try { await pintar(); }
  catch (ex) { m.cuerpo.innerHTML = `<p class="error-bloque">${esc(ex.message)}</p>`; }
}

function htmlRecibo(p) {
  return `<div class="recibo">
      <header><strong class="recibo-marca">MAGIS-AUTO, S.A.</strong><span>Crédito financiero automotriz, Jalapa, Guatemala</span></header>
      <h3>Recibo de caja ${esc(p.NumeroRecibo)}</h3>
      <dl class="datos">
        ${dato('Fecha y hora', fecha(p.FechaHora))}${dato('Cliente', p.Cliente)}${dato('Crédito', p.NumeroObligacion)}
        ${dato('Cuota', `${p.NumeroCuota}, vence el ${fecha(p.FechaVencimiento)}`)}${dato('Medio de pago', p.MedioPago)}
        ${dato('Referencia bancaria', p.ReferenciaBancaria ?? 'No aplica')}
      </dl>
      <p class="recibo-monto">${quetzales(p.Monto)}</p>
      ${p.Anulada ? '<p class="recibo-sello">Anulado</p>' : ''}
    </div>`;
}

function verRecibo(p) {
  const m = modal({
    titulo: 'Recibo de caja',
    contenido: htmlRecibo(p),
    pie: '<button type="button" class="btn btn-sec" data-cerrar>Cerrar</button><button type="button" class="btn btn-pri" data-imprimir>Imprimir recibo</button>'
  });
  $('[data-imprimir]', m.d).onclick = () => imprimir(htmlRecibo(p));
}

async function pPagos(args) {
  const v = $('#vista');
  v.innerHTML = encabezado('Pagos', 'Registro de pagos y abonos a las cuotas. Cada pago genera su recibo de caja.')
    + `<section><h2>Registrar pago</h2>
         <div class="rp">
           <div class="rp-credito">
             <div class="campo"><label for="rp-q">Crédito</label><input id="rp-q" placeholder="Número de obligación o cliente"></div>
             <select id="rp-lista" size="8" aria-label="Créditos activos"></select>
           </div>
           <div id="rp-detalle"><p class="nota">Elija un crédito para ver sus cuotas pendientes.</p></div>
         </div>
       </section>
       <section><h2>Pagos registrados</h2>
         <form class="filtros" id="pg-f">
           <div class="campo"><label for="pg-c">Cliente</label><input id="pg-c" name="Cliente"></div>
           <div class="campo"><label for="pg-d">Desde</label><input type="date" id="pg-d" name="Desde" value="${hoyISO(-30)}"></div>
           <div class="campo"><label for="pg-h">Hasta</label><input type="date" id="pg-h" name="Hasta" value="${hoyISO()}"></div>
           ${(await camposHTML([{ n: 'MedioPagoId', l: 'Medio de pago', t: 'select', fuente: { ruta: '/medios-pago', v: 'MedioPagoId', t: 'Descripcion' } }])).replace('<div class="rejilla-campos">', '').replace(/<\/div>$/, '')}
           <div class="campo campo-check"><input type="checkbox" id="pg-a" name="IncluirAnulados"><label for="pg-a">Incluir anulados</label></div>
           <div class="filtros-botones"><button class="btn btn-sec">Buscar</button></div>
         </form>
         <div id="pg-lista">${cargando}</div>
       </section>`;

  const medios = await catalogo('/medios-pago');
  let creditos = (await get('/creditos/buscar', { Estado: 'ACTIVO' }))[0] ?? [];

  const pintarLista = () => {
    const q = norm($('#rp-q').value);
    const visibles = creditos.filter(c => !q || norm(`${c.NumeroObligacion} ${c.Cliente}`).includes(q));
    $('#rp-lista').innerHTML = visibles.map(c =>
      `<option value="${c.CreditoId}">${esc(c.NumeroObligacion)}, ${esc(c.Cliente)}${c.DiasAtraso > 0 ? ` (${c.DiasAtraso} días de atraso)` : ''}</option>`).join('');
  };
  $('#rp-q').oninput = pintarLista;
  $('#rp-lista').onchange = () => elegir($('#rp-lista').value).catch(ex => aviso(ex.message, 'error'));
  pintarLista();

  async function elegir(creditoId) {
    const det = $('#rp-detalle');
    det.innerHTML = cargando;
    const c = creditos.find(x => String(x.CreditoId) === String(creditoId)) ?? primera(await get('/creditos/buscar', { CreditoId: creditoId }));
    if (!c) { det.innerHTML = '<p class="nota">El crédito no existe.</p>'; return; }
    const pendientes = ((await get('/cuotas/buscar', { CreditoId: creditoId }))[0] ?? []).filter(q => q.Estado !== 'PAGADA');
    const medioDefecto = medios.find(x => x.Codigo === 'EFE') ?? medios[0];

    det.innerHTML = `<div class="rp-enc"><strong>${esc(c.NumeroObligacion)}</strong><span>${esc(c.Cliente)}</span>
        ${c.Estado !== 'ACTIVO' ? insignia(c.Estado) : ''}<button type="button" class="btn-enlace" data-ficha>Ver crédito</button></div>
      ${pendientes.length && c.Estado === 'ACTIVO' ? `<form id="rp-form" class="formulario">
        <div class="tabla-envoltura"><table class="tabla tabla-eleccion"><thead><tr><th></th><th>Cuota</th><th>Vence</th><th class="num">Total</th><th class="num">Pagado</th><th class="num">Saldo</th><th class="num">Atraso</th></tr></thead>
        <tbody>${pendientes.slice(0, 6).map((q, i) => `<tr>
          <td><input type="radio" name="NumeroCuota" value="${q.NumeroCuota}" data-saldo="${q.SaldoCuota}"${i === 0 ? ' checked' : ''} aria-label="Cuota ${q.NumeroCuota}"></td>
          <td>${q.NumeroCuota}</td><td>${fecha(q.FechaVencimiento)}</td><td class="num">${quetzales(q.TotalCuota)}</td>
          <td class="num">${quetzales(q.MontoPagado)}</td><td class="num"><strong>${quetzales(q.SaldoCuota)}</strong></td>
          <td class="num">${q.DiasAtraso > 0 ? `<span class="texto-alerta">${q.DiasAtraso} días</span>` : 'Al día'}</td></tr>`).join('')}</tbody></table></div>
        <div class="rejilla-campos">
          <div class="campo"><label for="rp-monto">Monto recibido (Q)</label><input type="number" id="rp-monto" name="Monto" step="0.01" min="0.01" required></div>
          <div class="campo"><label for="rp-medio">Medio de pago</label><select id="rp-medio" name="MedioPagoId" required>
            ${medios.map(x => `<option value="${x.MedioPagoId}" data-ref="${x.RequiereReferencia ? 1 : 0}"${x === medioDefecto ? ' selected' : ''}>${esc(x.Descripcion)}</option>`).join('')}</select></div>
          <div class="campo" data-ref-campo><label for="rp-ref">Número de autorización o de boleta</label><input id="rp-ref" name="ReferenciaBancaria" maxlength="40"></div>
        </div>
        <p class="nota">Si el monto es menor al saldo, queda como abono parcial a la cuota.</p>
        <p class="error-form" hidden></p>
        <div class="acciones-form"><button class="btn btn-pri">Registrar pago</button></div>
      </form>` : '<p class="nota">Este crédito no tiene cuotas pendientes.</p>'}`;

    $('[data-ficha]', det).onclick = () => fichaCredito(creditoId, async () => { await recargarCreditos(); await elegir(creditoId); });
    const form = $('#rp-form', det);
    if (!form) return;
    const monto = $('#rp-monto', form);
    const medio = $('#rp-medio', form);
    const ref = $('#rp-ref', form);
    const fijarMonto = () => {
      const r = $('input[name="NumeroCuota"]:checked', form);
      monto.value = Number(r.dataset.saldo).toFixed(2);
      monto.max = Number(r.dataset.saldo).toFixed(2);
    };
    const fijarReferencia = () => {
      const requiere = medio.selectedOptions[0]?.dataset.ref === '1';
      ref.required = requiere;
      $('[data-ref-campo]', form).hidden = !requiere;
      if (!requiere) ref.value = '';
    };
    $$('input[name="NumeroCuota"]', form).forEach(r => { r.onchange = fijarMonto; });
    medio.onchange = fijarReferencia;
    fijarMonto();
    fijarReferencia();

    form.onsubmit = async e => {
      e.preventDefault();
      const error = $('.error-form', form);
      const boton = $('button.btn-pri', form);
      error.hidden = true;
      boton.disabled = true;
      try {
        const p = primera(await api('POST', '/pagos', { CreditoId: creditoId, ...leerCampos(form) }));
        verRecibo(p);
        aviso(`Pago registrado con el recibo ${p.NumeroRecibo}.`);
        await recargarCreditos();
        await elegir(creditoId);
        await cargarHistorial();
      } catch (ex) {
        error.textContent = ex.message;
        error.hidden = false;
        boton.disabled = false;
      }
    };
  }

  async function recargarCreditos() {
    creditos = (await get('/creditos/buscar', { Estado: 'ACTIVO' }))[0] ?? [];
    pintarLista();
  }

  async function cargarHistorial() {
    const p = leerCampos($('#pg-f'));
    p.IncluirAnulados = p.IncluirAnulados ? 1 : 0;
    const filas = (await get('/pagos/buscar', p))[0];
    tabla($('#pg-lista'), filas, {
      vacio: 'No hay pagos con ese criterio.',
      columnas: [{ c: 'NumeroRecibo', t: 'Recibo' }, { c: 'FechaHora', t: 'Fecha' }, { c: 'Cliente' }, { c: 'NumeroObligacion', t: 'Crédito' },
                 { c: 'NumeroCuota', t: 'Cuota' }, { c: 'MedioPago', t: 'Medio de pago' }, { c: 'ReferenciaBancaria', t: 'Referencia' },
                 { c: 'Monto' }, { c: 'Anulada', t: 'Estado', html: f => (f.Anulada ? insignia('ANULADO') : insignia('ACTIVO')) }],
      totales: ['Monto'],
      acciones: f => [{ acc: 'recibo', texto: 'Recibo' }, ...(f.Anulada ? [] : [{ acc: 'anular', texto: 'Anular', clase: 'peligro' }])],
      alAccion: async (a, f) => {
        if (a === 'recibo') verRecibo(f);
        if (a === 'anular') {
          if (!await confirmar(`¿Anular el recibo ${f.NumeroRecibo} por ${quetzales(f.Monto)}? El saldo vuelve a la cuota ${f.NumeroCuota}.`, 'Anular')) return;
          try {
            const r = primera(await api('DELETE', `/pagos/${f.TransaccionId}`));
            aviso(r?.Mensaje ?? 'Pago anulado.');
            await cargarHistorial();
            await recargarCreditos();
          } catch (ex) { aviso(ex.message, 'error'); }
        }
      }
    });
  }
  $('#pg-f').onsubmit = e => { e.preventDefault(); cargarHistorial().catch(ex => aviso(ex.message, 'error')); };
  await cargarHistorial();

  if (args?.[0]) {
    $('#rp-lista').value = args[0];
    await elegir(args[0]);
  }
}

const PARAMS_REPORTE = {
  Desde:         { l: 'Desde', t: 'date', req: true, def: () => hoyISO(0, -24) },
  Hasta:         { l: 'Hasta', t: 'date', req: true, def: () => hoyISO() },
  FechaCorte:    { l: 'Fecha de corte', t: 'date', def: () => hoyISO() },
  DiasMinimo:    { l: 'Días mínimos de atraso', t: 'number', min: 1, paso: 1, def: 1 },
  Mes:           { l: 'Mes', t: 'select', vacio: false, def: () => String(new Date().getMonth() + 1),
                   opciones: ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'].map((m, i) => [String(i + 1), m.charAt(0).toUpperCase() + m.slice(1)]) },
  ClienteId:     { l: 'Cliente', t: 'select', fuente: FUENTES.clientes },
  CreditoId:     { l: 'Crédito', t: 'select', fuente: FUENTES.creditos },
  VendedorId:    { l: 'Vendedor', t: 'select', fuente: FUENTES.vendedores },
  Dias:          { l: 'Días hacia adelante', t: 'number', min: 1, paso: 1, def: 7 },
  PrecioContado: { l: 'Precio de contado (Q)', t: 'number', req: true, min: 1, paso: '0.01', def: 165000 },
  Enganche:      { l: 'Enganche (Q)', t: 'number', req: true, min: 0, paso: '0.01', def: 33000 },
  PlazoMeses:    { l: 'Plazo en meses', t: 'number', min: 1, maxv: 120, paso: 1, def: 60 },
  TasaAnual:     { l: 'Tasa anual (%)', t: 'number', min: 0.01, paso: '0.01', def: 12.5 }
};
const REQUERIDOS_REPORTE = { 6: ['ClienteId'], 7: ['CreditoId'] };
const DEFAULTS_REPORTE = { 10: { Desde: () => hoyISO(), Hasta: () => hoyISO(0, 12) } };
const TITULOS_RESULTADOS = {
  1: ['Créditos emitidos', 'Totales del período'],
  2: ['Créditos en mora', 'Resumen'],
  3: ['Movimiento por medio de pago', 'Detalle de pagos'],
  6: ['Cliente', 'Créditos', 'Pagos realizados'],
  7: ['Crédito', 'Plan de pagos'],
  8: ['Comisión por vendedor', 'Detalle por pago'],
  9: ['Costo real por crédito', 'Historial de valor de los vehículos'],
  11: ['Intereses por mes', 'Intereses por crédito activo'],
  12: ['Saldos por crédito activo', 'Resumen por estado'],
  15: ['Riesgo respaldado por fiador', 'Créditos activos sin fiador'],
  16: ['Clientes morosos', 'Referencias personales', 'Fiadores'],
  24: ['Resumen', 'Tabla de amortización simulada']
};
const TOTALES_REPORTE = {
  1: [['PrecioContado', 'Enganche', 'MontoFinanciado', 'TotalIntereses', 'TotalRecaudable']],
  2: [['CuotasVencidas', 'MontoVencido', 'SaldoTotalCredito']],
  3: [['Transacciones', 'TotalRecaudado'], ['Monto']],
  4: [['CreditosColocados', 'TotalVentas', 'TotalFinanciado']],
  7: [null, ['Interes', 'Capital', 'ManejoCuenta', 'SeguroAuto', 'SeguroVida', 'TotalCuota', 'MontoPagado']],
  8: [['PagosRecibidos', 'MontoBaseComision', 'ComisionAPagar'], ['Monto', 'ComisionVendedor']],
  10: [['CuotasPorCobrar', 'Capital', 'Intereses', 'ManejoCuenta', 'Seguros', 'TotalEsperado']],
  11: [['InteresDevengado', 'InteresCobrado', 'InteresPendiente'], ['TotalIntereses', 'InteresDevengadoAlDia', 'InteresPorDevengar']],
  12: [['MontoFinanciado', 'CapitalPendiente', 'TotalPagado', 'SaldoPendiente']],
  14: [['Creditos', 'TotalVentas', 'TotalFinanciado']],
  17: [['MontoPagado', 'SaldoCuota']],
  19: [['Creditos', 'MontoFinanciado', 'CarteraVigente', 'CreditosEnMora']],
  21: [['SaldoCuota']],
  23: [['Monto']]
};

async function pReportes(args, consulta) {
  if (args?.[0]) return verReporte(Number(args[0]), consulta);
  const lista = await catalogo('/reportes');
  $('#vista').innerHTML = encabezado('Reportes financieros', '')
    + `<ol class="lista-reportes">${lista.map(r => `<li><a href="#/reportes/${r.Numero}">
        <span class="lr-num">${r.Numero}</span>
        <span class="lr-texto"><strong>${esc(r.Nombre)}</strong><span>${esc(r.Razon)}</span></span></a></li>`).join('')}</ol>`;
}

async function verReporte(n, consulta) {
  const lista = await catalogo('/reportes');
  const r = lista.find(x => x.Numero === n);
  if (!r) throw new Error(`El reporte ${n} no existe.`);
  const nombres = r.Parametros.startsWith('(') ? [] : r.Parametros.split(',').map(s => s.trim().replace('@', ''));
  const campos = nombres.map(nombre => {
    const c = { n: nombre, ...PARAMS_REPORTE[nombre] };
    if (REQUERIDOS_REPORTE[n]?.includes(nombre)) c.req = true;
    if (DEFAULTS_REPORTE[n]?.[nombre]) c.def = DEFAULTS_REPORTE[n][nombre];
    if (consulta?.has(nombre)) c.def = consulta.get(nombre);
    return c;
  });

  $('#vista').innerHTML = '<a class="volver" href="#/reportes">Todos los reportes</a>'
    + encabezado(`${n}. ${r.Nombre}`, r.Razon)
    + `<form class="filtros filtros-reporte" id="rp-f">${campos.length ? await camposHTML(campos) : '<p class="nota">Este reporte no necesita parámetros.</p>'}
         <div class="filtros-botones"><button class="btn btn-pri">Generar reporte</button>
         <button type="button" class="btn btn-sec" id="rp-imp" disabled>Imprimir</button>
         <button type="button" class="btn btn-sec" id="rp-csv" disabled>Exportar a Excel</button></div>
       </form><div id="rp-res"></div>`;

  let ultimo = null;
  const ejecutar = async () => {
    const form = $('#rp-f');
    if (!form.reportValidity()) return;
    const res = $('#rp-res');
    res.innerHTML = cargando;
    try {
      ultimo = await get('/reportes/' + n, leerCampos(form));
      pintarReporte(n, ultimo, res);
      $('#rp-imp').disabled = false;
      $('#rp-csv').disabled = false;
    } catch (ex) {
      res.innerHTML = `<div class="error-bloque">${esc(ex.message)}</div>`;
    }
  };
  $('#rp-f').onsubmit = e => { e.preventDefault(); ejecutar(); };
  $('#rp-imp').onclick = () => imprimir(`<h1>${esc(`${n}. ${r.Nombre}`)}</h1><p>${esc(r.Razon)}</p><p>Generado el ${esc(new Date().toLocaleString('es-GT'))}.</p>${$('#rp-res').innerHTML}`);
  $('#rp-csv').onclick = () => descargarCSV(`reporte-${pad(n)}-${norm(r.Nombre).replace(/[^a-z0-9]+/g, '-')}.csv`, ultimo, TITULOS_RESULTADOS[n]);
  if (campos.every(c => !c.req || (c.def !== undefined && c.def !== ''))) await ejecutar();
}

function pintarReporte(n, tablas, cont) {
  const titulos = TITULOS_RESULTADOS[n] ?? [];
  cont.innerHTML = '';
  if (n === 22) { cont.innerHTML = `<section class="resultado">${cuadroIndicadores(primera(tablas))}</section>`; return; }

  tablas.forEach((filas, i) => {
    const sec = document.createElement('section');
    sec.className = 'resultado';
    if (titulos[i] || tablas.length > 1) sec.innerHTML = `<h2>${esc(titulos[i] ?? `Resultado ${i + 1}`)}</h2>`;
    const cuerpo = document.createElement('div');
    sec.append(cuerpo);
    cont.append(sec);

    if (n === 24 && i === 0) { cuerpo.innerHTML = `<div class="costo-real costo-real-amplio">${panelCostoReal(filas[0])}</div>`; return; }
    if (n === 13) {
      cuerpo.innerHTML = barrasMora(filas) + '<div class="resultado" data-t></div>';
      tabla($('[data-t]', cuerpo), filas, { ocultar: ['Orden'], totales: ['Creditos', 'MontoVencido', 'PorcentajeDeCartera'] });
      return;
    }
    if (n === 5) {
      cuerpo.innerHTML = filas.length
        ? `<div class="cartas">${filas.map(f => `<article class="carta">
            <p class="carta-dest">${esc(f.Cliente)}, cumple ${f.EdadQueCumple} años el día ${f.Dia}<br>
            <small>${esc(f.Correo)}${f.Telefonos ? `, teléfono ${esc(f.Telefonos)}` : ''}</small></p>
            <pre class="carta-texto">${esc(f.Carta)}</pre></article>`).join('')}</div>`
        : '<p class="vacio-tabla">Ningún cliente activo cumple años en ese mes.</p>';
      return;
    }

    const opc = { totales: TOTALES_REPORTE[n]?.[i] ?? undefined, vacio: 'No hay datos para estos parámetros.' };
    if ((n === 7 && i === 1) || n === 2) opc.claseFila = f => (f.DiasAtraso > 0 ? 'fila-atraso' : '');
    if (n === 18) {
      filas = filas.map(f => (String(f.MedioPago).startsWith('***') ? { ...f, MedioPago: 'Total del día' } : f));
      opc.claseFila = f => (f.MedioPago === 'Total del día' ? 'fila-total' : '');
    }
    tabla(cuerpo, filas, opc);
  });
}

function csvCelda(v) {
  if (v === null || v === undefined) return '';
  let s = String(v);
  if (/^\d{4}-\d{2}-\d{2}T/.test(s)) s = fecha(s);
  return /[;"\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

function descargarCSV(nombre, tablas, titulos = []) {
  if (!tablas) return;
  const lineas = [];
  tablas.forEach((filas, i) => {
    if (!filas.length) return;
    if (tablas.length > 1) lineas.push(csvCelda(titulos[i] ?? `Resultado ${i + 1}`));
    const cols = Object.keys(filas[0]);
    lineas.push(cols.map(c => csvCelda(etiqueta(c))).join(';'));
    filas.forEach(f => lineas.push(cols.map(c => csvCelda(f[c])).join(';')));
    lineas.push('');
  });
  const blob = new Blob(['﻿' + lineas.join('\r\n')], { type: 'text/csv;charset=utf-8' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = nombre;
  document.body.append(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(a.href), 2000);
}

const CATALOGOS = [
  { clave: 'marcas', titulo: 'Marcas de vehículos', id: 'MarcaId',
    campos: [{ n: 'CodigoMarca', l: 'Código interno', req: true, max: 10 }, { n: 'Nombre', req: true, max: 50 }],
    buscar: [{ n: 'Nombre' }, { n: 'CodigoMarca', l: 'Código interno' }] },
  { clave: 'agencias', titulo: 'Agencias y regiones', id: 'AgenciaId',
    campos: [{ n: 'Nombre', req: true, max: 80 }, { n: 'Region', l: 'Región', req: true, max: 50 }],
    buscar: [{ n: 'Nombre' }, { n: 'Region', l: 'Región' }] },
  { clave: 'vendedores', titulo: 'Vendedores', id: 'VendedorId', ocultar: ['AgenciaId', 'Nombres', 'Apellidos'],
    campos: [
      { n: 'CodigoEmpleado', l: 'Código de empleado', req: true, max: 10 },
      { n: 'DPI', req: true, max: 13, patron: '\\d{13}' },
      { n: 'Nombres', req: true, max: 80 }, { n: 'Apellidos', req: true, max: 80 },
      { n: 'AgenciaId', l: 'Agencia', t: 'select', req: true, fuente: FUENTES.agencias },
      { n: 'Activo', t: 'check', soloEditar: true }],
    buscar: [{ n: 'Nombre' }, { n: 'CodigoEmpleado', l: 'Código de empleado' },
             { n: 'AgenciaId', l: 'Agencia', t: 'select', fuente: FUENTES.agencias }, { n: 'Activo', t: 'select', opciones: SI_NO }] },
  { clave: 'medios-pago', titulo: 'Medios de pago', id: 'MedioPagoId',
    campos: [
      { n: 'MedioPagoId', l: 'Identificador', t: 'number', req: true, soloNuevo: true, min: 1, maxv: 255, paso: 1 },
      { n: 'Codigo', l: 'Código', req: true, max: 5 },
      { n: 'Descripcion', l: 'Descripción', req: true, max: 40 },
      { n: 'RequiereReferencia', l: 'Exige número de autorización o boleta', t: 'check' }],
    buscar: [{ n: 'Descripcion', l: 'Descripción' }, { n: 'Codigo', l: 'Código' }] },
  { clave: 'tipos-telefono', titulo: 'Tipos de teléfono', id: 'TipoTelefonoId',
    campos: [
      { n: 'TipoTelefonoId', l: 'Identificador', t: 'number', req: true, soloNuevo: true, min: 1, maxv: 255, paso: 1 },
      { n: 'Descripcion', l: 'Descripción', req: true, max: 20 }],
    buscar: [{ n: 'Descripcion', l: 'Descripción' }] },
  { clave: 'parametros', titulo: 'Parámetros del sistema', id: 'Codigo', tipos: { Valor: 'numero' },
    nota: 'Los cambios aplican solo a créditos nuevos.',
    campos: [
      { n: 'Codigo', l: 'Código', req: true, max: 30, soloNuevo: true },
      { n: 'Valor', t: 'number', req: true, paso: '0.0001', min: 0 },
      { n: 'Descripcion', l: 'Descripción', req: true, max: 200, ancho: true }],
    buscar: [{ n: 'Codigo', l: 'Código' }, { n: 'Texto', l: 'Descripción' }] },
  { clave: 'personas', titulo: 'Personas', id: 'PersonaId',
    nota: '',
    buscar: [{ n: 'Nombre' }, { n: 'DPI' }, { n: 'NIT' },
             { n: 'EsCliente', l: 'Es cliente', t: 'select', opciones: SI_NO }, { n: 'EsFiador', l: 'Es fiador', t: 'select', opciones: SI_NO }] },
  { clave: 'referencias', titulo: 'Referencias personales', id: 'ReferenciaId',
    campos: [
      { n: 'ClienteId', l: 'Cliente', t: 'select', req: true, soloNuevo: true, fuente: FUENTES.clientes },
      { n: 'NombreCompleto', l: 'Nombre completo', req: true, max: 160 },
      { n: 'Parentesco', l: 'Parentesco o relación', req: true, max: 40, lista: 'lista-parentescos' },
      { n: 'LugarTrabajo', l: 'Lugar de trabajo', max: 120 }],
    buscar: [{ n: 'ClienteId', l: 'Cliente', t: 'select', fuente: FUENTES.clientes }, { n: 'Nombre' }, { n: 'Parentesco' }] },
  { clave: 'telefonos-persona', titulo: 'Teléfonos de clientes y fiadores', id: 'TelefonoPersonaId',
    campos: [
      { n: 'PersonaId', l: 'Persona', t: 'select', req: true, soloNuevo: true, fuente: FUENTES.personas },
      { n: 'TipoTelefonoId', l: 'Tipo', t: 'select', req: true, fuente: FUENTES.tipos },
      { n: 'Numero', l: 'Número', req: true, max: 15 }],
    buscar: [{ n: 'PersonaId', l: 'Persona', t: 'select', fuente: FUENTES.personas }, { n: 'Numero', l: 'Número' }] },
  { clave: 'direcciones-persona', titulo: 'Direcciones de clientes y fiadores', id: 'DireccionPersonaId',
    campos: [
      { n: 'PersonaId', l: 'Persona', t: 'select', req: true, soloNuevo: true, fuente: FUENTES.personas },
      { n: 'Direccion', l: 'Dirección', req: true, max: 200, ancho: true },
      { n: 'Municipio', req: true, max: 60 }, { n: 'Departamento', req: true, max: 40 }],
    buscar: [{ n: 'PersonaId', l: 'Persona', t: 'select', fuente: FUENTES.personas }, { n: 'Texto', l: 'Dirección' }, { n: 'Municipio' }, { n: 'Departamento' }] },
  { clave: 'telefonos-referencia', titulo: 'Teléfonos de referencias', id: 'TelefonoReferenciaId',
    campos: [
      { n: 'ReferenciaId', l: 'Referencia', t: 'select', req: true, soloNuevo: true, fuente: FUENTES.referencias },
      { n: 'TipoTelefonoId', l: 'Tipo', t: 'select', req: true, fuente: FUENTES.tipos },
      { n: 'Numero', l: 'Número', req: true, max: 15 }],
    buscar: [{ n: 'ClienteId', l: 'Cliente', t: 'select', fuente: FUENTES.clientes }, { n: 'Numero', l: 'Número' }] },
  { clave: 'direcciones-referencia', titulo: 'Direcciones de referencias', id: 'DireccionReferenciaId',
    campos: [
      { n: 'ReferenciaId', l: 'Referencia', t: 'select', req: true, soloNuevo: true, fuente: FUENTES.referencias },
      { n: 'Direccion', l: 'Dirección', req: true, max: 200, ancho: true },
      { n: 'Municipio', req: true, max: 60 }, { n: 'Departamento', req: true, max: 40 }],
    buscar: [{ n: 'ClienteId', l: 'Cliente', t: 'select', fuente: FUENTES.clientes }, { n: 'Texto', l: 'Dirección' }, { n: 'Municipio' }] },
  { clave: 'historial-valor', titulo: 'Historial de valor de vehículos', id: 'HistorialValorId',
    campos: [
      { n: 'VIN', l: 'Vehículo', t: 'select', req: true, soloNuevo: true, fuente: FUENTES.vehiculos },
      { n: 'Fecha', t: 'date', req: true, def: () => hoyISO() },
      { n: 'ValorEstimado', l: 'Valor estimado (Q)', t: 'number', req: true, min: 0, paso: '0.01' },
      { n: 'Concepto', req: true, max: 100, ancho: true }],
    buscar: [{ n: 'VIN' }, { n: 'Desde', t: 'date' }, { n: 'Hasta', t: 'date' }] },
  { clave: 'creditos-fiadores', titulo: 'Fiadores por crédito', id: 'CreditoId', textoEditar: 'Sustituir',
    campos: [
      { n: 'CreditoId', l: 'Crédito', t: 'select', req: true, soloNuevo: true, fuente: FUENTES.creditosActivos },
      { n: 'FiadorId', l: 'Fiador', t: 'select', req: true, soloNuevo: true, fuente: FUENTES.fiadores },
      { n: 'FiadorIdNuevo', l: 'Fiador que lo sustituye', t: 'select', req: true, soloEditar: true, fuente: FUENTES.fiadores }],
    extraEditar: f => ({ FiadorIdAnterior: f.FiadorId }),
    extraEliminar: f => ({ FiadorId: f.FiadorId }),
    buscar: [{ n: 'CreditoId', l: 'Crédito', t: 'select', fuente: FUENTES.creditos }, { n: 'Fiador' }, { n: 'DPIFiador', l: 'DPI del fiador' }] },
  { clave: 'cuotas', titulo: 'Cuotas del plan de pagos', id: 'CuotaId', textoNuevo: 'Generar plan', textoEditar: 'Reprogramar',
    nota: '',
    campos: [
      { n: 'CreditoId', l: 'Crédito', t: 'select', req: true, soloNuevo: true, fuente: FUENTES.creditosActivos },
      { n: 'FechaVencimiento', l: 'Nueva fecha de vencimiento', t: 'date', req: true, soloEditar: true }],
    idEliminar: f => f.CreditoId,
    confirmarEliminar: f => `¿Eliminar el plan de pagos completo del crédito ${f.NumeroObligacion}?`,
    textoEliminar: 'Eliminar plan',
    buscar: [{ n: 'NumeroObligacion', l: 'Crédito', ph: 'MA-00000001' },
             { n: 'Estado', t: 'select', opciones: [['PENDIENTE', 'Pendiente'], ['PARCIAL', 'Parcial'], ['PAGADA', 'Pagada']] },
             { n: 'SoloVencidas', l: 'Solo vencidas', t: 'select', opciones: [['1', 'Sí']] },
             { n: 'Desde', l: 'Vence desde', t: 'date' }, { n: 'Hasta', l: 'Vence hasta', t: 'date' }] }
];

async function pCatalogos(args) {
  const actual = CATALOGOS.find(c => c.clave === args?.[0]) ?? CATALOGOS[0];
  $('#vista').innerHTML = encabezado('Catálogos', '')
    + `<div class="catalogos">
         <nav class="cat-menu" aria-label="Catálogos">${CATALOGOS.map(c => `<a href="#/catalogos/${c.clave}"${c === actual ? ' class="activo" aria-current="page"' : ''}>${esc(c.titulo)}</a>`).join('')}</nav>
         <div class="cat-contenido" id="cat">${cargando}</div>
       </div>`;
  await crudGenerico($('#cat'), actual);
}

async function crudGenerico(cont, cfg) {
  const puedeAgregar = cfg.campos?.some(c => !c.soloEditar);
  const puedeEditar = cfg.campos?.some(c => !c.soloNuevo);
  cont.innerHTML = `<div class="cat-enc"><h2>${esc(cfg.titulo)}</h2>${puedeAgregar ? `<button type="button" class="btn btn-pri" data-nuevo>${esc(cfg.textoNuevo ?? 'Agregar')}</button>` : ''}</div>
    ${cfg.nota ? `<p class="nota">${esc(cfg.nota)}</p>` : ''}
    <form class="filtros" data-filtros>${await camposHTML(cfg.buscar ?? [])}
      <div class="filtros-botones"><button class="btn btn-sec">Buscar</button><button type="button" class="btn-enlace" data-todos>Mostrar todos</button></div>
    </form>
    <div data-lista>${cargando}</div>`;

  const lista = $('[data-lista]', cont);
  const filtros = $('[data-filtros]', cont);
  const pintar = filas => tabla(lista, filas, {
    tipos: cfg.tipos,
    ocultar: cfg.ocultar,
    acciones: cfg.campos ? () => [
      ...(puedeEditar ? [{ acc: 'editar', texto: cfg.textoEditar ?? 'Editar' }] : []),
      { acc: 'eliminar', texto: cfg.textoEliminar ?? 'Eliminar', clase: 'peligro' }
    ] : null,
    alAccion: accion
  });
  const listar = async () => pintar((await get('/' + cfg.clave))[0]);
  const buscar = async () => pintar((await get(`/${cfg.clave}/buscar`, leerCampos(filtros)))[0]);
  let ultimaCarga = listar;
  const recargar = () => {
    delete cache['/' + cfg.clave];
    return ultimaCarga();
  };

  filtros.onsubmit = e => { e.preventDefault(); ultimaCarga = buscar; buscar().catch(ex => aviso(ex.message, 'error')); };
  $('[data-todos]', cont).onclick = () => { filtros.reset(); ultimaCarga = listar; listar().catch(ex => aviso(ex.message, 'error')); };
  const botonNuevo = $('[data-nuevo]', cont);
  if (botonNuevo) {
    botonNuevo.onclick = () => formularioModal({
      titulo: `${cfg.titulo}: ${cfg.textoNuevo ? cfg.textoNuevo.toLowerCase() : 'agregar registro'}`,
      campos: cfg.campos, modo: 'nuevo',
      alGuardar: async d => { await api('POST', '/' + cfg.clave, d); aviso('Registro agregado.'); await recargar(); }
    }).catch(ex => aviso(ex.message, 'error'));
  }

  async function accion(a, f) {
    if (a === 'editar') {
      formularioModal({
        titulo: `${cfg.titulo}: ${(cfg.textoEditar ?? 'editar').toLowerCase()}`,
        campos: cfg.campos, valores: f, modo: 'editar',
        alGuardar: async d => {
          await api('PUT', `/${cfg.clave}/${encodeURIComponent(f[cfg.id])}`, { ...d, ...(cfg.extraEditar?.(f) ?? {}) });
          aviso('Cambios guardados.');
          await recargar();
        }
      }).catch(ex => aviso(ex.message, 'error'));
    }
    if (a === 'eliminar') {
      if (!await confirmar(cfg.confirmarEliminar?.(f) ?? '¿Eliminar este registro?')) return;
      try {
        const id = cfg.idEliminar ? cfg.idEliminar(f) : f[cfg.id];
        const r = primera(await api('DELETE', `/${cfg.clave}/${encodeURIComponent(id)}${qs(cfg.extraEliminar?.(f))}`));
        aviso(r?.Mensaje ?? 'Registro eliminado.');
        await recargar();
      } catch (ex) { aviso(ex.message, 'error'); }
    }
  }

  await listar();
}

function criteriosBusqueda(texto) {
  const t = texto.trim();
  if (!t) return null;
  if (/^\d{13}$/.test(t)) return { clientes: { DPI: t }, fiadores: { DPI: t }, creditos: { DPI: t } };
  if (/^MA-?\d+$/i.test(t)) return { creditos: { NumeroObligacion: t.toUpperCase() } };
  if (/^[A-HJ-NPR-Z0-9]{17}$/i.test(t) && /\d/.test(t)) return { vehiculos: { VIN: t.toUpperCase() }, creditos: { VIN: t.toUpperCase() } };
  if (/^P?\d{3}[A-Z]{3}$/i.test(t)) return { vehiculos: { Placa: t.toUpperCase() } };
  if (/^\d+[Kk]?$/.test(t)) return { clientes: { NIT: t }, fiadores: { NIT: t }, creditos: { NumeroObligacion: t } };
  return { clientes: { Nombre: t }, fiadores: { Nombre: t }, creditos: { Cliente: t }, vehiculos: { Linea: t } };
}

async function pConsultas(args, consulta) {
  const inicial = consulta?.get('q') ?? '';
  $('#vista').innerHTML = encabezado('Consultas', 'Busque en todo el sistema por nombre, DPI, NIT, número de crédito, VIN o placa.')
    + `<form class="tarjeta buscador" id="cs-f" role="search">
         ${icono('buscar')}
         <input id="cs-q" type="search" value="${esc(inicial)}" placeholder="Por ejemplo: Pérez, 1234567890101, MA-00000001 o P512FGH" aria-label="Texto a buscar">
         <button class="btn btn-pri">Buscar</button>
       </form>
       <div id="cs-res"></div>`;

  const secciones = {
    clientes:  { titulo: 'Clientes', ic: 'cliente', columnas: [{ c: 'ClienteId', t: 'Código' }, { c: 'NombreCompleto', t: 'Nombre' }, { c: 'DPI' }, { c: 'NIT' }, { c: 'Telefonos', t: 'Teléfonos' }, { c: 'CreditosActivos', t: 'Créditos activos' }],
                 abrir: f => fichaPersona(CFG_CLIENTES, f.ClienteId, buscar) },
    fiadores:  { titulo: 'Fiadores', ic: 'fiadores', columnas: [{ c: 'FiadorId', t: 'Código' }, { c: 'NombreCompleto', t: 'Nombre' }, { c: 'DPI' }, { c: 'NIT' }, { c: 'CreditosRespaldados', t: 'Créditos respaldados' }],
                 abrir: f => fichaPersona(CFG_FIADORES, f.FiadorId, buscar) },
    creditos:  { titulo: 'Créditos', ic: 'monedas', columnas: [{ c: 'NumeroObligacion', t: 'Crédito' }, { c: 'Cliente' }, { c: 'Vehiculo', t: 'Vehículo', v: f => `${f.Marca} ${f.Linea} ${f.Anio}` }, { c: 'SaldoPendiente' }, { c: 'DiasAtraso', t: 'Días de atraso' }, { c: 'Estado' }],
                 abrir: f => fichaCredito(f.CreditoId, buscar) },
    vehiculos: { titulo: 'Vehículos', ic: 'auto', columnas: [{ c: 'VIN' }, { c: 'Marca' }, { c: 'Linea', t: 'Línea' }, { c: 'Anio', t: 'Año' }, { c: 'Placa' }, { c: 'ValorAgencia', t: 'Valor de agencia' }, { c: 'EstadoGarantia', t: 'Estado' }],
                 abrir: f => historialValor(f), textoAbrir: 'Historial de valor' }
  };

  async function buscar() {
    const texto = $('#cs-q').value;
    const crit = criteriosBusqueda(texto);
    const res = $('#cs-res');
    if (!crit) { res.innerHTML = '<p class="nota">Escriba lo que quiere buscar.</p>'; return; }
    history.replaceState(null, '', `#/consultas?q=${encodeURIComponent(texto.trim())}`);
    res.innerHTML = cargando;
    const claves = Object.keys(crit);
    const resultados = await Promise.all(claves.map(k => get(`/${k}/buscar`, crit[k]).then(t => t[0] ?? [])));
    const total = resultados.reduce((s, r) => s + r.length, 0);
    if (!total) { res.innerHTML = `<p class="vacio-tabla resultado">No se encontró nada para "${esc(texto.trim())}".</p>`; return; }
    res.innerHTML = '';
    claves.forEach((k, i) => {
      if (!resultados[i].length) return;
      const s = secciones[k];
      const sec = document.createElement('section');
      sec.className = 'tarjeta resultado';
      sec.innerHTML = `<div class="tarjeta-enc">${icono(s.ic)}<h2>${s.titulo}</h2><span class="contador">${resultados[i].length} ${resultados[i].length === 1 ? 'resultado' : 'resultados'}</span></div><div></div>`;
      res.append(sec);
      tabla(sec.lastElementChild, resultados[i], {
        columnas: s.columnas,
        acciones: () => [{ acc: 'abrir', texto: s.textoAbrir ?? 'Abrir' }],
        alAccion: (a, f) => s.abrir(f)
      });
    });
  }

  $('#cs-f').onsubmit = e => { e.preventDefault(); buscar().catch(ex => aviso(ex.message, 'error')); };
  $('#cs-q').focus();
  if (inicial) await buscar();
}

const PAGINAS = {
  inicio: pInicio,
  clientes: args => pPersonas(CFG_CLIENTES, args),
  fiadores: args => pPersonas(CFG_FIADORES, args),
  vehiculos: pVehiculos,
  creditos: pCreditos,
  pagos: pPagos,
  consultas: pConsultas,
  reportes: pReportes,
  catalogos: pCatalogos
};

function abrirGrupo(btn, abierto) {
  btn.setAttribute('aria-expanded', String(abierto));
  $('#' + btn.getAttribute('aria-controls')).hidden = !abierto;
}

function prepararMenu() {
  $('#g-catalogos').innerHTML = CATALOGOS.map(c => `<a href="#/catalogos/${c.clave}"><span>${esc(c.titulo)}</span></a>`).join('');
  $$('.grupo-btn').forEach(btn => { btn.onclick = () => abrirGrupo(btn, btn.getAttribute('aria-expanded') !== 'true'); });
  const botonMovil = $('.menu-movil');
  botonMovil.onclick = () => {
    const abierto = $('#lateral').classList.toggle('abierto');
    botonMovil.setAttribute('aria-expanded', String(abierto));
  };
  document.addEventListener('click', e => {
    const u = $('.usuario');
    if (u.open && !u.contains(e.target)) u.open = false;
  });
}

function marcarMenu(rutaActual, pagina) {
  const enlaces = $$('#menu a');
  let mejor = null;
  enlaces.forEach(a => {
    const h = a.getAttribute('href').slice(2);
    if ((rutaActual === h || rutaActual.startsWith(h + '/')) && (!mejor || h.length > mejor.getAttribute('href').length - 2)) mejor = a;
  });
  enlaces.forEach(a => {
    a.classList.toggle('activo', a === mejor);
    if (a === mejor) a.setAttribute('aria-current', 'page'); else a.removeAttribute('aria-current');
  });
  $$('.grupo').forEach(g => {
    const btn = $('.grupo-btn', g);
    const contiene = mejor && g.contains(mejor);
    btn.classList.toggle('activo', Boolean(contiene) || (!mejor && g.dataset.grupo === pagina));
    if (contiene || (!mejor && g.dataset.grupo === pagina)) abrirGrupo(btn, true);
  });
  $('#lateral').classList.remove('abierto');
  $('.menu-movil').setAttribute('aria-expanded', 'false');
  $('.usuario').open = false;
}

async function actualizarCampana() {
  try {
    const k = primera(await get('/reportes/22'));
    const mora = Number(k?.CreditosEnMora ?? 0);
    $('#campana .punto').hidden = mora === 0;
    const texto = mora ? `${mora} ${mora === 1 ? 'crédito' : 'créditos'} en mora. Ver cartera en mora` : 'Sin créditos en mora';
    $('#campana').setAttribute('aria-label', texto);
    $('#campana').title = texto;
  } catch {   }
}

async function navegar() {
  const [ruta, consulta] = location.hash.replace(/^#\/?/, '').split('?');
  const [nombre, ...args] = ruta.split('/');
  const pagina = PAGINAS[nombre] ? nombre : 'inicio';
  iconoActual = ICONO_PAGINA[pagina];
  marcarMenu(PAGINAS[nombre] ? ruta : 'inicio', pagina);
  actualizarCampana();
  const vista = $('#vista');
  vista.innerHTML = cargando;
  window.scrollTo(0, 0);
  try {
    await PAGINAS[pagina](args.map(decodeURIComponent), new URLSearchParams(consulta ?? ''));
  } catch (ex) {
    vista.innerHTML = `<div class="error-bloque"><h2>No se pudo cargar esta sección</h2><p>${esc(ex.message)}</p>
      <p class="nota">Revise que SQL Server esté encendido y que la cadena de conexión de appsettings.json apunte a la base MagisAuto.</p></div>`;
  }
}

prepararMenu();
window.addEventListener('hashchange', navegar);
navegar();
