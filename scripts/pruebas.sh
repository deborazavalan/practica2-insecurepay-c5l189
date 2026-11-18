#!/usr/bin/env bash
set -euo pipefail
URL="${URL:-http://localhost:8080}"

estado() { curl -sS -o /dev/null -w "%{http_code}" "$@"; }

TOKEN=$(curl -sS -X POST "$URL/api/auth/login" -H "Content-Type: application/json" \
  -d '{"username":"carlos_mora","password":"carlos123"}' | jq -r .token)
echo "Token de carlos_mora obtenido: ${TOKEN:0:20}..."

echo
echo "=== Paso 1: intento IDOR bloqueado (carlos_mora -> cuenta 3 de maria_rojas) ==="
curl -sS -i -X GET "$URL/api/cuentas/3/saldo" -H "Authorization: Bearer $TOKEN" | tee /tmp/paso1.txt
echo
head -1 /tmp/paso1.txt | grep -q " 403"
grep -qi "application/problem+json" /tmp/paso1.txt
if grep -q "4850000" /tmp/paso1.txt; then exit 1; fi

echo
echo "=== Paso 2: consulta legitima (carlos_mora -> su cuenta, ID 2 en data.sql) ==="
curl -sS -i -X GET "$URL/api/cuentas/2/saldo" -H "Authorization: Bearer $TOKEN" | tee /tmp/paso2.txt
echo
head -1 /tmp/paso2.txt | grep -q " 200"

echo
echo "=== Extra: cuenta 1 (admin) solicitada por carlos_mora ==="
echo "HTTP $(estado "$URL/api/cuentas/1/saldo" -H "Authorization: Bearer $TOKEN")"
test "$(estado "$URL/api/cuentas/1/saldo" -H "Authorization: Bearer $TOKEN")" = "403"

echo "=== Extra: GET /api/cuentas/3 (detalle) por carlos_mora ==="
test "$(estado "$URL/api/cuentas/3" -H "Authorization: Bearer $TOKEN")" = "403" && echo "HTTP 403"

echo "=== Extra: sin cabecera Authorization ==="
test "$(estado "$URL/api/cuentas/3/saldo")" = "401" && echo "HTTP 401"

echo "=== Extra: token manipulado ==="
test "$(estado "$URL/api/cuentas/2/saldo" -H "Authorization: Bearer ${TOKEN}x")" = "401" && echo "HTTP 401"

echo "=== Extra: cuenta inexistente ==="
test "$(estado "$URL/api/cuentas/999/saldo" -H "Authorization: Bearer $TOKEN")" = "404" && echo "HTTP 404"

ADMIN=$(curl -sS -X POST "$URL/api/auth/login" -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r .token)
echo "=== Extra: rol ADMIN consulta cuenta 3 ==="
test "$(estado "$URL/api/cuentas/3/saldo" -H "Authorization: Bearer $ADMIN")" = "200" && echo "HTTP 200"

echo
echo "RESULTADO: todas las verificaciones pasaron"
