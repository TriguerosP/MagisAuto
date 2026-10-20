# MAGIS-AUTO — Sistema de Crédito Financiero Automotriz

Proyecto final del curso Base de Datos I

MAGIS-AUTO es un sistema web para administrar créditos de vehículos: registra clientes y fiadores, los vehículos que quedan en garantía, emite créditos con su plan de pagos, recibe pagos y genera 24 reportes financieros.


## Qué hace la aplicación

Módulo: Qué permite hacer 
**Clientes** Registrar personas como clientes, con sus teléfonos, direcciones y referencias personales.  
**Fiadores** Registrar fiadores y asignarlos a los créditos.  
**Vehículos en garantía**   Registrar el vehículo (VIN, placa, marca, línea, modelo) y llevar el historial de su valor.  
**Créditos** Simular el costo real del crédito, emitirlo y generar automáticamente su plan de pagos (cuotas).  
**Pagos** Registrar pagos de cuotas (completos o abonos parciales), emitir recibo y anular pagos.  
**Consultas** Buscar rápidamente por DPI, NIT, placa, VIN o número de crédito.  
**Reportes financieros** 24 reportes que se pueden imprimir o exportar a Excel (CSV).  
**Catálogos** Mantenimiento de parámetros del sistema (tasa de interés, etc.), tipos de teléfono, medios de pago, marcas, agencias y vendedores.  


## Requisitos

SQL Server Management Studio (SSMS)   Cualquiera reciente   
.NET SDK   8.x   
Visual Studio 2022   
Navegador   Chrome, Edge o Firefox   

## Instalación paso a paso


### Crear la base de datos

1. Abrir SSMS y conéctate a tu servidor anotar el nombre del servidor que aparece en la ventana "Conectar" (por ejemplo `localhost\SQLEXPRESS`)
2. Abre y ejecuta con F5, los scripts de la carpeta `BaseDeDatos/` en este orden:
    
     1   `01_MagisAuto_Tablas.sql`  
     2   `02_MagisAuto_SP_Catalogos.sql`  
     3   `03_MagisAuto_SP_Creditos_Pagos.sql`  
     4   `04_MagisAuto_Reportes.sql`  
     5   `05_MagisAuto_DatosPrueba.sql`  

3. Al terminar, actualiza el explorador de objetos: debe aparecer la base MagisAuto. El script 01 borra y vuelve a crear la base MagisAuto si ya existe.

### Configurar la cadena de conexión

Abrir MagisAuto.Api/appsettings.json. la cadena por defecto es:

"ConnectionStrings": {
  "MagisAuto": "Server=localhost\\SQLEXPRESS;Database=MagisAuto;Trusted_Connection=True;TrustServerCertificate=True;"
}

Cambia el valor de Server= por el nombre de tu servidor de SSMS.

### Ejecutar la aplicación

**Opción A, con Visual Studio 2022:**

1. Abrir el archivo MagisAuto.sln.
2. Presiona F5 o el botón http.
3. Se abre el navegador con el sistema.

**Opción B, con la terminal:**

cd MagisAuto.Api
dotnet run

### Abrir el sistema

  Dirección  
  Sistema-interfaz web  http://localhost:5080  

## 5. Manual de uso

El menú lateral organiza el sistema en secciones:

### Inicio
Tablero con los indicadores principales de la cartera. La campana de la parte superior lleva al reporte de cartera en mora.

### Operación

- **Clientes**: presiona **Registrar cliente** para registrar un cliente con su DPI, NIT, nombre, fecha de nacimiento, correo, teléfonos y direcciones. En el mismo formulario puedes agregar varios teléfonos, direcciones y **referencias personales** (*Agregar otro teléfono*, *Agregar otra dirección*, *Agregar otra referencia*). Desde el detalle del cliente puedes usar *Editar datos* o *Eliminar*.
- **Fiadores**: con **Registrar fiador** registra a las personas que respaldan créditos. Una misma persona puede ser cliente en un crédito y fiador en otro sin duplicar sus datos.
- **Vehículos en garantía**: con **Registrar vehículo** registra el vehículo con su VIN, placa, marca, línea, modelo y valor. Con **Registrar valuación** se guarda el historial de cambios de valor.
- **Créditos**:
  1. Presiona **Emitir crédito** y elige el cliente, el vehículo y el vendedor.
  2. Ingresa el precio, el enganche y el plazo.
  3. Mientras escribes, el sistema muestra la **simulación** del costo real: cuota mensual, lo que pagará en total, cuánto paga de más y el valor del auto al terminar.
  4. Confirma con **Emitir crédito**: el sistema genera su plan de pagos automáticamente.
  5. En el detalle del crédito puedes **Asignar fiador**, **Editar condiciones** e **Imprimir plan de pagos**.
- **Pagos**:
  - *Registrar pago*: busca el crédito, indica el monto y el medio de pago y presiona **Registrar pago**. Al terminar puedes **Imprimir recibo**. Se aceptan abonos parciales y un pago se puede **Anular**.
  - *Cierre de caja* y *Pagos anulados*: accesos directos a esos reportes.

### Consultas
Escribe un DPI (13 dígitos), un NIT, una placa, un VIN o un número de crédito, y el sistema busca en clientes, fiadores, vehículos y créditos.

### Reportes financieros
Elige un reporte, completa sus parámetros (fechas, cliente, crédito, etc.) y presiona **Generar reporte**. Cada reporte se puede **Imprimir** o **Exportar a Excel** (archivo CSV). La lista completa está en la siguiente sección.

### Catálogos
Mantenimiento (crear, editar, eliminar y buscar) de: parámetros del sistema (por ejemplo la tasa de interés), tipos de teléfono, medios de pago, marcas, agencias y vendedores.

## Reportes disponibles

  1   Créditos emitidos por período   Desde, Hasta   Volumen de créditos colocados, montos financiados e intereses.  
  2   Cartera en mora   Días mínimos, Fecha de corte   Créditos con cuotas vencidas, para priorizar el cobro.  
  3   Pagos por medio de pago   Desde, Hasta   Movimiento por tipo de pago y el medio más utilizado.  
  4   Ventas por vendedor   Desde, Hasta   Créditos colocados por vendedor, ordenados de mayor a menor.  
  5   Cumpleañeros del mes   Mes   Clientes que cumplen años, con carta de felicitación.  
  6   Estado de cuenta por cliente   Cliente   Créditos, pagado, saldo, atraso y detalle de pagos.  
  7   Plan de pagos por crédito   Crédito   Tabla de amortización con el desglose de cada cuota.  
  8   Comisiones de vendedores   Desde, Hasta, Vendedor   Comisión sobre los pagos efectivamente recibidos.  
  9   Costo real vs. depreciación   Crédito   Total a pagar comparado con el valor futuro del vehículo.  
  10   Proyección de recaudación   Desde, Hasta   Dinero esperado mes a mes de las cuotas pendientes.  
  11   Intereses devengados   Desde, Hasta   Intereses generados por mes, cobrados y pendientes.  
  12   Saldos de cartera   —   Saldo de capital y total de cada crédito activo.  
  13   Antigüedad de la mora   Fecha de corte   Cartera vencida por rangos: 1-30, 31-60, 61-90 y más de 90 días.  
  14   Créditos por marca y línea   Desde, Hasta   Marcas y líneas más financiadas.  
  15   Exposición de fiadores   —   Saldo que respalda cada fiador y créditos sin fiador.  
  16   Directorio de cobros   Días mínimos   Contactos del cliente moroso, sus referencias y fiadores.  
  17   Cuotas con abonos parciales   —   Cuotas con abonos que aún no se liquidan.  
  18   Cierre de caja diario   Desde, Hasta   Recaudación por día y por medio de pago.  
  19   Colocación por agencia y región   Desde, Hasta   Desempeño de cada agencia y región.  
  20   Puntualidad de clientes   —   Porcentaje de cuotas pagadas a tiempo por cliente.  
  21   Cuotas por vencer   Días   Cuotas próximas a vencer con datos de contacto.  
  22   Resumen ejecutivo   —   Indicadores para gerencia: cartera, mora, recaudación y colocación.  
  23   Pagos anulados   Desde, Hasta   Recibos anulados (control de auditoría).  
  24   Simulador de crédito   Precio, Enganche, Plazo, Tasa   Cuota y costo total antes de solicitar el crédito.  

## Posibles Errores a la hora de ejecutar

  --No se pudo conectar con la API: La aplicación no está en ejecución. Repite el paso 4.  
  --No se pudo cargar esta sección: Revisar que SQL Server esté encendido y que la cadena de conexión sea correcta.  
  --Could not find stored procedure: Faltan los scripts 02, 03 o 04. Ejecútalos en orden.  
  --Cannot open database MagisAuto: Falta el script 01, o el usuario no tiene permiso sobre la base.  
  --dotnet no se reconoce como comando: Instala el .NET 8 SDK y abre una terminal nueva.  
  --Error al descargar paquetes de NuGet: Revisa tu conexión a internet y vuelve a ejecutar `dotnet run`.  
  --El puerto 5080 está ocupado: Cambia el puerto en `MagisAuto.Api/Properties/launchSettings.json`.  
  --La página carga en blanco o sin estilos: Revisa que exista la carpeta `MagisAuto.Api/MagisWeb` con index.html, css/ y js/.  
