from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from restaurante.models import (
    AuthUserUbicacionFisica,
    CatalogoClasificacion,
    DetalleDocumento,
    DetalleUbicacion,
    LibroCuentaContable,
    Presentacion,
    SucursalSistema,
    TipoCuentaContable,
    UbicacionFisica,
    UnidadMedida,
)


class ApiEndpointTests(APITestCase):
    def setUp(self):
        user_model = get_user_model()
        self.user = user_model.objects.create_user(
            username="api-user",
            email="api@example.com",
            password="password",
        )
        self.other_user = user_model.objects.create_user(
            username="location-user",
            email="location@example.com",
            password="password",
        )
        self.client.force_authenticate(self.user)

        self.sucursal = SucursalSistema.objects.create(
            id=1,
            nombre="Sucursal Centro",
            direccion="Av. Central 100",
            personacontacto="Ana",
            telefono1="555-0100",
            identificadorcorto="CEN",
        )
        CatalogoClasificacion.objects.create(
            id=1,
            nombreclasificacion="Bebidas",
            estatus="A",
        )
        UnidadMedida.objects.create(id=1, unidadmedida="Pieza")
        Presentacion.objects.create(id=1, nombrepresentacion="Botella", tipo="Compra")
        TipoCuentaContable.objects.create(id=1, nombre="Activo", estatus="A")

        self.ubicacion = UbicacionFisica.objects.create(
            id=10,
            id_sucursalsistema=self.sucursal.id,
            nombre="Caja Principal",
            descripcion="Caja de cobro principal",
            tipo="Caja",
            estatus="A",
            cuenta_contable=99,
        )
        DetalleUbicacion.objects.create(
            id=20,
            id_ubicacionfisica=self.ubicacion.id,
            direccion="Planta baja",
            telefono="555-9999",
            horariorecepcion="09:00-18:00",
            saldoactual=125,
            tipo="Caja",
        )

    def test_health_is_public(self):
        self.client.force_authenticate(user=None)

        response = self.client.get("/api/v1/health/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json(), {"status": "ok"})

    def test_sucursales_and_catalogs_are_readable(self):
        endpoints = {
            "/api/v1/sucursales/": "Sucursal Centro",
            "/api/v1/catalogos/clasificaciones/": "Bebidas",
            "/api/v1/catalogos/unidades-medida/": "Pieza",
            "/api/v1/catalogos/presentaciones/": "Botella",
            "/api/v1/catalogos/tipos-cuenta-contable/": "Activo",
        }

        for url, expected_value in endpoints.items():
            with self.subTest(url=url):
                response = self.client.get(url)

                self.assertEqual(response.status_code, status.HTTP_200_OK)
                self.assertIn(expected_value, str(response.json()))

    def test_ubicaciones_list_and_detail_include_location_detail(self):
        list_response = self.client.get("/api/v1/ubicaciones/")
        detail_response = self.client.get(f"/api/v1/ubicaciones/{self.ubicacion.id}/")

        self.assertEqual(list_response.status_code, status.HTTP_200_OK)
        self.assertEqual(detail_response.status_code, status.HTTP_200_OK)
        self.assertEqual(list_response.json()[0]["nombre"], "Caja Principal")
        self.assertEqual(detail_response.json()["detalle"]["saldoactual"], 125)

    def test_create_ubicacion_with_detail(self):
        payload = {
            "sucursal_id": self.sucursal.id,
            "nombre": "Almacen Seco",
            "descripcion": "Insumos no perecederos",
            "tipo": "Almacen",
            "estatus": "A",
            "detalle": {
                "direccion": "Bodega 1",
                "saldoactual": 0,
                "tipo": "Almacen",
            },
        }

        response = self.client.post("/api/v1/ubicaciones/", payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.json()["detalle"]["direccion"], "Bodega 1")
        self.assertTrue(UbicacionFisica.objects.filter(nombre="Almacen Seco").exists())

    def test_status_balance_and_typed_location_endpoints_work(self):
        status_response = self.client.patch(
            f"/api/v1/ubicaciones/{self.ubicacion.id}/status/",
            {"estatus": "S"},
            format="json",
        )
        balance_response = self.client.get(f"/api/v1/ubicaciones/{self.ubicacion.id}/balance/")
        typed_response = self.client.get("/api/v1/cajas/")

        self.assertEqual(status_response.status_code, status.HTTP_200_OK)
        self.assertEqual(status_response.json()["estatus"], "S")
        self.assertEqual(balance_response.status_code, status.HTTP_200_OK)
        self.assertEqual(balance_response.json(), {"ubicacion_id": self.ubicacion.id, "saldo_actual": 125})
        self.assertEqual(typed_response.status_code, status.HTTP_200_OK)
        self.assertEqual(typed_response.json()[0]["tipo"], "Caja")

    def test_location_user_assignment_lifecycle(self):
        assign_response = self.client.post(
            f"/api/v1/ubicaciones/{self.ubicacion.id}/users/",
            {"user_id": self.other_user.id},
            format="json",
        )
        list_response = self.client.get(f"/api/v1/ubicaciones/{self.ubicacion.id}/users/")
        delete_response = self.client.delete(
            f"/api/v1/ubicaciones/{self.ubicacion.id}/users/{self.other_user.id}/",
        )

        self.assertEqual(assign_response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(list_response.status_code, status.HTTP_200_OK)
        self.assertEqual(list_response.json()[0]["username"], "location-user")
        self.assertEqual(delete_response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(AuthUserUbicacionFisica.objects.exists())

    def test_disable_blocks_open_documents_and_positive_balances(self):
        DetalleDocumento.objects.create(id_ubicacionfisica1=self.ubicacion.id, estatus="A")

        open_doc_response = self.client.post(f"/api/v1/ubicaciones/{self.ubicacion.id}/disable/")

        self.assertEqual(open_doc_response.status_code, status.HTTP_409_CONFLICT)

        DetalleDocumento.objects.all().delete()
        LibroCuentaContable.objects.create(id_cuentacontable=self.ubicacion.cuenta_contable, saldo=1)

        positive_balance_response = self.client.post(f"/api/v1/ubicaciones/{self.ubicacion.id}/disable/")

        self.assertEqual(positive_balance_response.status_code, status.HTTP_409_CONFLICT)

    def test_disable_marks_location_inactive_when_domain_checks_pass(self):
        response = self.client.post(f"/api/v1/ubicaciones/{self.ubicacion.id}/disable/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json()["estatus"], "I")
        self.ubicacion.refresh_from_db()
        self.assertEqual(self.ubicacion.estatus, "I")
