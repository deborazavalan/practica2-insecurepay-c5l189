# Práctica Preparatoria 2 — InsecurePay

IF0009 Desarrollo de Software IV · UCR Sede del Atlántico · Débora Zavala (C5L189)

Diseño adaptativo móvil, mitigación de IDOR/BOLA (OWASP A01:2021) con JWT y Nginx como proxy inverso.

| Parte | Ubicación |
| :--- | :--- |
| Parte 1 — Teoría aplicada | [`RESPUESTAS.md`](RESPUESTAS.md) |
| 2.1.1 Excepción y ProblemDetail RFC 7807 | `backend/src/main/java/cr/ac/ucr/if0009/insecurepay/exception/` |
| 2.1.2 Validación de propiedad | `service/CuentaService.java`, `controller/CuentaController.java`, `util/JwtUtil.java` |
| 2.2 Interceptor HTTP Angular | `frontend/src/app/interceptors/auth.interceptor.ts`, `app.config.ts` |
| 2.3 Verificación DAST | `scripts/pruebas.sh`, [`evidencias/pruebas-curl.txt`](evidencias/pruebas-curl.txt) |

En `data.sql` la cuenta de `carlos_mora` es la **ID 2** (la ID 1 pertenece a `admin`), por lo que la consulta legítima del Paso 2 se hace sobre la cuenta 2.

## Ejecución

```bash
cd backend && ./mvnw spring-boot:run
cd frontend && npm install && npm start
bash scripts/pruebas.sh
```

El workflow `.github/workflows/verificacion.yml` compila backend y frontend, levanta la API y ejecuta `scripts/pruebas.sh` en cada push. La salida de esa ejecución está en `evidencias/pruebas-curl.txt`.
