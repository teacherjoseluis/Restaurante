from django.urls import include, path
from rest_framework.routers import DefaultRouter

from restaurante.api.views import (
    AlmacenViewSet,
    AreaPreparacionViewSet,
    CajaViewSet,
    CatalogoClasificacionViewSet,
    HealthView,
    MesaViewSet,
    PresentacionViewSet,
    SucursalSistemaViewSet,
    TipoCuentaContableViewSet,
    UbicacionFisicaViewSet,
    UnidadMedidaViewSet,
)


router = DefaultRouter()
router.register("sucursales", SucursalSistemaViewSet, basename="sucursal")
router.register("catalogos/clasificaciones", CatalogoClasificacionViewSet, basename="clasificacion")
router.register("catalogos/unidades-medida", UnidadMedidaViewSet, basename="unidad-medida")
router.register("catalogos/presentaciones", PresentacionViewSet, basename="presentacion")
router.register(
    "catalogos/tipos-cuenta-contable",
    TipoCuentaContableViewSet,
    basename="tipo-cuenta-contable",
)
router.register("ubicaciones", UbicacionFisicaViewSet, basename="ubicacion")
router.register("mesas", MesaViewSet, basename="mesa")
router.register("cajas", CajaViewSet, basename="caja")
router.register("areas-preparacion", AreaPreparacionViewSet, basename="area-preparacion")
router.register("almacenes", AlmacenViewSet, basename="almacen")

urlpatterns = [
    path("health/", HealthView.as_view(), name="api-health"),
    path("", include(router.urls)),
]
