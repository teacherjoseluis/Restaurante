from django.contrib.auth import get_user_model
from django.db import transaction
from django.db.models import Q
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from restaurante.api.exceptions import ConflictError
from restaurante.api.serializers import (
    AssignUserSerializer,
    CatalogoClasificacionSerializer,
    PresentacionSerializer,
    StatusSerializer,
    SucursalSistemaSerializer,
    TipoCuentaContableSerializer,
    UbicacionFisicaSerializer,
    UnidadMedidaSerializer,
    UserSummarySerializer,
)
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


class HealthView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        return Response({"status": "ok"})


class SucursalSistemaViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = SucursalSistema.objects.all()
    serializer_class = SucursalSistemaSerializer


class CatalogoClasificacionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = CatalogoClasificacion.objects.all()
    serializer_class = CatalogoClasificacionSerializer


class UnidadMedidaViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = UnidadMedida.objects.all()
    serializer_class = UnidadMedidaSerializer


class PresentacionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Presentacion.objects.all()
    serializer_class = PresentacionSerializer


class TipoCuentaContableViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = TipoCuentaContable.objects.all()
    serializer_class = TipoCuentaContableSerializer


class UbicacionFisicaViewSet(viewsets.ModelViewSet):
    queryset = UbicacionFisica.objects.all()
    serializer_class = UbicacionFisicaSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        tipo = self.request.query_params.get("tipo")
        sucursal_id = self.request.query_params.get("sucursal_id")
        estatus = self.request.query_params.get("estatus")
        if tipo:
            queryset = queryset.filter(tipo=tipo)
        if sucursal_id:
            queryset = queryset.filter(id_sucursalsistema=sucursal_id)
        if estatus:
            queryset = queryset.filter(estatus=estatus)
        return queryset

    @action(detail=True, methods=["patch"], url_path="status")
    def set_status(self, request, pk=None):
        ubicacion = self.get_object()
        serializer = StatusSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        ubicacion.estatus = serializer.validated_data["estatus"]
        ubicacion.save(update_fields=["estatus"])
        return Response(self.get_serializer(ubicacion).data)

    @action(detail=True, methods=["post"], url_path="disable")
    def disable(self, request, pk=None):
        ubicacion = self.get_object()
        self._assert_can_disable(ubicacion)
        ubicacion.estatus = "I"
        ubicacion.save(update_fields=["estatus"])
        return Response(self.get_serializer(ubicacion).data)

    @action(detail=True, methods=["get"], url_path="balance")
    def balance(self, request, pk=None):
        ubicacion = self.get_object()
        detalle = DetalleUbicacion.objects.filter(id_ubicacionfisica=ubicacion.id).first()
        if detalle is None:
            return Response(
                {"detail": "Location detail not found."},
                status=status.HTTP_404_NOT_FOUND,
            )
        return Response(
            {
                "ubicacion_id": ubicacion.id,
                "saldo_actual": detalle.saldoactual,
            }
        )

    @action(detail=True, methods=["get", "post"], url_path="users")
    def users(self, request, pk=None):
        ubicacion = self.get_object()
        user_model = get_user_model()

        if request.method == "GET":
            users = user_model.objects.filter(
                ubicaciones_fisicas__ubicacionfisica=ubicacion,
            ).order_by("id")
            return Response(UserSummarySerializer(users, many=True).data)

        serializer = AssignUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = user_model.objects.get(id=serializer.validated_data["user_id"])
        relation, created = AuthUserUbicacionFisica.objects.get_or_create(
            user=user,
            ubicacionfisica=ubicacion,
        )
        response_status = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        return Response(UserSummarySerializer(relation.user).data, status=response_status)

    @action(detail=True, methods=["delete"], url_path=r"users/(?P<user_id>\d+)")
    def user_detail(self, request, pk=None, user_id=None):
        ubicacion = self.get_object()
        deleted, _ = AuthUserUbicacionFisica.objects.filter(
            user_id=user_id,
            ubicacionfisica=ubicacion,
        ).delete()
        if deleted == 0:
            return Response({"detail": "User assignment not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @staticmethod
    def _assert_can_disable(ubicacion):
        open_document_exists = DetalleDocumento.objects.filter(
            Q(id_ubicacionfisica1=ubicacion.id) | Q(id_ubicacionfisica2=ubicacion.id),
        ).exclude(estatus="C").exists()
        if open_document_exists:
            raise ConflictError("Location has non-closed document details.")

        if ubicacion.cuenta_contable is None:
            return

        positive_balance_exists = LibroCuentaContable.objects.filter(
            id_cuentacontable=ubicacion.cuenta_contable,
            saldo__gt=0,
        ).exists()
        if positive_balance_exists:
            raise ConflictError("Location accounting account has a positive balance.")


class TypedUbicacionFisicaViewSet(UbicacionFisicaViewSet):
    tipo = None

    def get_queryset(self):
        return UbicacionFisica.objects.filter(tipo=self.tipo).order_by("id")

    def perform_create(self, serializer):
        with transaction.atomic():
            serializer.save(tipo=self.tipo)


class MesaViewSet(TypedUbicacionFisicaViewSet):
    tipo = "Mesa"


class CajaViewSet(TypedUbicacionFisicaViewSet):
    tipo = "Caja"


class AreaPreparacionViewSet(TypedUbicacionFisicaViewSet):
    tipo = "AreaPreparacion"


class AlmacenViewSet(TypedUbicacionFisicaViewSet):
    tipo = "Almacen"
