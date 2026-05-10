# Middleware API design

This repository now exposes the first middleware/API slice with Django REST Framework under
`/api/v1/`.

## Conventions

- Version prefix: `/api/v1/`.
- Authentication: all endpoints require Django authentication except `GET /api/v1/health/`.
- Error shape: `{"detail": "..."}` for domain, validation, not-found, and conflict errors.
- Location disable conflicts return HTTP `409` when a location still has open document details or
  a positive accounting balance.
- Models preserve legacy table and column names so the HTTP layer can sit over the existing schema.

## First endpoint set

### Health

```text
GET /api/v1/health/
```

Returns `{"status": "ok"}` and does not require authentication.

### Read-only branch and catalog endpoints

```text
GET /api/v1/sucursales/
GET /api/v1/sucursales/{id}/

GET /api/v1/catalogos/clasificaciones/
GET /api/v1/catalogos/clasificaciones/{id}/
GET /api/v1/catalogos/unidades-medida/
GET /api/v1/catalogos/unidades-medida/{id}/
GET /api/v1/catalogos/presentaciones/
GET /api/v1/catalogos/presentaciones/{id}/
GET /api/v1/catalogos/tipos-cuenta-contable/
GET /api/v1/catalogos/tipos-cuenta-contable/{id}/
```

### Physical location endpoints

```text
GET    /api/v1/ubicaciones/
POST   /api/v1/ubicaciones/
GET    /api/v1/ubicaciones/{id}/
PATCH  /api/v1/ubicaciones/{id}/
PATCH  /api/v1/ubicaciones/{id}/status/
POST   /api/v1/ubicaciones/{id}/disable/
GET    /api/v1/ubicaciones/{id}/balance/
GET    /api/v1/ubicaciones/{id}/users/
POST   /api/v1/ubicaciones/{id}/users/
DELETE /api/v1/ubicaciones/{id}/users/{user_id}/
```

Location list supports optional filters:

```text
?tipo=Caja
?sucursal_id=1
?estatus=A
```

Typed convenience endpoints use the same serializer and validation:

```text
GET/POST /api/v1/mesas/
GET/POST /api/v1/cajas/
GET/POST /api/v1/areas-preparacion/
GET/POST /api/v1/almacenes/
```

## Next endpoint candidates

The next slice should expose Registro Maestro read/write operations and context endpoints after
the request/response contract for physical locations is reviewed.
