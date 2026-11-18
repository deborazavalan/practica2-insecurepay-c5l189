# Práctica Preparatoria 2 — Parte 1: Teoría Aplicada

## 1.1 Diagnóstico de `RenderFlex overflowed`

1. **Causa raíz:** `Row` mide a sus hijos no flexibles con restricciones horizontales no acotadas (`maxWidth = ∞`). Cada hijo toma su ancho intrínseco: `ancho(Icon) + ancho(Column) + ancho(Text saldo)`. El ancho de la `Column` es el del texto más largo (el nombre de 35 caracteres a 18 px). Si esa suma supera el ancho disponible de la `Card` (`maxWidth` del `Row`), la diferencia (48.7 px) se reporta como desbordamiento y se pintan las franjas amarillas y negras.
2. **Corrección:** envolver la `Column` en **`Expanded`** (equivale a `Flexible` con `fit: FlexFit.tight`). El `Row` primero coloca el ícono y el saldo y entrega a la columna exactamente el ancho restante, con lo que el saldo nunca sale de la pantalla.
3. **Elipsis:**

```dart
Text(
  nombreCliente,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(fontSize: 18),
)
```

## 1.2 `LayoutBuilder` vs `MediaQuery`

1. **Diferencia:** `MediaQuery.of(context).size` da el tamaño de toda la ventana o pantalla, sin importar dónde esté el widget. `LayoutBuilder` entrega los `BoxConstraints` que el padre inmediato le asigna a ese nodo concreto del árbol (el espacio real disponible).
2. **Master-Detail:** en una tableta o web, el panel lateral puede medir 320 px aunque la pantalla mida 1280 px. Si el componente decide su diseño con `MediaQuery`, cree que tiene 1280 px, elige un diseño ancho y se desborda o se ve mal. Además no es reutilizable: su comportamiento depende de la pantalla y no del contenedor. `LayoutBuilder` decide según el espacio real del panel.

## 1.3 IDOR / BOLA (OWASP A01:2021)

1. **Definición:** IDOR (*Insecure Direct Object Reference*), llamado BOLA (*Broken Object Level Authorization*) en el OWASP API Top 10, ocurre cuando la aplicación usa un identificador provisto por el cliente (`/cuentas/{id}`) para acceder directamente a un objeto sin verificar que el usuario tenga permiso sobre ese objeto. OWASP la clasifica en **A01 – Broken Access Control** porque es una falla de control de acceso (CWE-639 / CWE-862); A01 es la categoría número 1 porque se encontró en el 94 % de las aplicaciones evaluadas.
2. **Autenticación ≠ autorización:** un JWT válido solo prueba *quién* es el usuario (autenticación). No dice nada sobre *qué* puede hacer con la cuenta `{id}` (autorización). Si el servidor no compara el propietario de la cuenta con el `sub` del token, Carlos, con su propio token perfectamente válido, puede cambiar `{id}` a 3 y leer el saldo de María. El token no impide el ataque: lo realiza un usuario legítimamente autenticado.
3. **Escalamiento:** es **horizontal**. Un cliente accede a recursos de otro cliente con el mismo nivel de privilegio. Sería vertical si un cliente obtuviera funciones de un rol superior (ADMIN).

## 1.4 OWASP Mobile M3 — Comunicaciones inseguras

> En el OWASP Mobile Top 10 (2016) es **M3 – Insecure Communication**; en la edición 2024 es **M5**.

1. **MitM:** el atacante se coloca entre el teléfono y el servidor, por ejemplo con un punto de acceso Wi-Fi falso, ARP spoofing o DNS spoofing en una red pública. Con `http://`, todo viaja en texto plano: puede leer la cabecera `Authorization: Bearer <jwt>`, números de cuenta y saldos, reutilizar el token para suplantar al usuario e incluso modificar las respuestas o peticiones en tránsito.
2. **Defensas nativas:**
   - Android (`res/xml/network_security_config.xml`, referenciado desde el manifiesto):
     ```xml
     <network-security-config>
         <base-config cleartextTrafficPermitted="false" />
     </network-security-config>
     ```
     (equivalente a `android:usesCleartextTraffic="false"`; desde API 28 es el valor por defecto).
   - iOS (`Info.plist`): ATS activo con `NSAppTransportSecurity` → `NSAllowsArbitraryLoads = false` y sin excepciones `NSExceptionAllowsInsecureHTTPLoads`.
3. **Certificate / SSL pinning:** la app incrusta el certificado o el hash SPKI de la clave pública del servidor y, durante el handshake TLS, rechaza cualquier certificado que no coincida, aunque una CA del sistema lo considere válido. En Flutter se implementa con un `SecurityContext` que confía solo en el certificado propio, o con `badCertificateCallback`/paquetes como `http_certificate_pinning`. Protege contra una CA raíz maliciosa instalada en el dispositivo (proxies corporativos, Burp/mitmproxy, malware) y contra CA comprometidas que emitan certificados fraudulentos para el dominio.

## 1.5 Nginx como proxy inverso

1. **`proxy_pass`:** Nginx recibe la petición del cliente en el puerto 80 para `api.insecurepay.cr`, abre una conexión con el proceso Spring Boot en `127.0.0.1:8080`, le reenvía la petición (con las cabeceras `Host`, `X-Real-IP`, `X-Forwarded-For` y `X-Forwarded-Proto`), espera la respuesta y la devuelve al cliente. El cliente nunca habla directamente con Spring Boot.
2. **Sin `X-Forwarded-For`:** Spring Boot vería como origen la IP de Nginx, `127.0.0.1`, para todos los usuarios. Los logs de auditoría perderían la IP real de cada cliente y el rate limiting trataría a todos como un único cliente: un atacante podría bloquear a todos, o el límite resultaría inútil.
3. **Aislamiento de puertos:** si 8080 está abierto, un atacante puede saltarse Nginx y con ello TLS (443), el rate limiting, los filtros WAF, las cabeceras de seguridad y la compresión, y además falsificar `X-Forwarded-For`. Con `ufw deny 8080` y `ufw allow 80,443/tcp` (o con `server.address=127.0.0.1` en Spring), la única superficie expuesta es el proxy, que aplica todas las políticas.
