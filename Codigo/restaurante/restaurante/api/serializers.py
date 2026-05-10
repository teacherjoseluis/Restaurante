from django.contrib.auth import get_user_model
from django.db import transaction
from rest_framework import serializers

from restaurante.models import (
    CatalogoClasificacion,
    DetalleUbicacion,
    Presentacion,
    SucursalSistema,
    TipoCuentaContable,
    UbicacionFisica,
    UnidadMedida,
)


class SucursalSistemaSerializer(serializers.ModelSerializer):
    class Meta:
        model = SucursalSistema
        fields = [
            "id",
            "nombre",
            "direccion",
            "personacontacto",
            "telefono1",
            "telefono2",
            "telefono3",
            "correoelectronico",
            "id_cliente",
            "identificadorcorto",
        ]


class CatalogoClasificacionSerializer(serializers.ModelSerializer):
    class Meta:
        model = CatalogoClasificacion
        fields = ["id", "nombreclasificacion", "estatus"]


class UnidadMedidaSerializer(serializers.ModelSerializer):
    class Meta:
        model = UnidadMedida
        fields = ["id", "unidadmedida"]


class PresentacionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Presentacion
        fields = ["id", "nombrepresentacion", "tipo"]


class TipoCuentaContableSerializer(serializers.ModelSerializer):
    class Meta:
        model = TipoCuentaContable
        fields = ["id", "nombre", "estatus"]


class DetalleUbicacionSerializer(serializers.ModelSerializer):
    class Meta:
        model = DetalleUbicacion
        fields = [
            "direccion",
            "telefono",
            "horariorecepcion",
            "saldoactual",
            "impresora",
            "terminalsalida",
            "minimocomensales",
            "maximocomensales",
            "tipo",
        ]


class UbicacionFisicaSerializer(serializers.ModelSerializer):
    sucursal_id = serializers.IntegerField(source="id_sucursalsistema", allow_null=True, required=False)
    subcuenta_contable_id = serializers.IntegerField(
        source="id_subcuentacontable",
        allow_null=True,
        required=False,
    )
    detalle = DetalleUbicacionSerializer(required=False, allow_null=True)

    class Meta:
        model = UbicacionFisica
        fields = [
            "id",
            "sucursal_id",
            "nombre",
            "descripcion",
            "tipo",
            "subcuenta_contable_id",
            "estatus",
            "cuenta_contable",
            "detalle",
        ]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        detalle = DetalleUbicacion.objects.filter(id_ubicacionfisica=instance.id).first()
        data["detalle"] = DetalleUbicacionSerializer(detalle).data if detalle else None
        return data

    @transaction.atomic
    def create(self, validated_data):
        detalle_data = validated_data.pop("detalle", None)
        ubicacion = UbicacionFisica.objects.create(**validated_data)
        if detalle_data:
            DetalleUbicacion.objects.create(id_ubicacionfisica=ubicacion.id, **detalle_data)
        return ubicacion

    @transaction.atomic
    def update(self, instance, validated_data):
        detalle_data = validated_data.pop("detalle", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if detalle_data is not None:
            detalle, _created = DetalleUbicacion.objects.get_or_create(id_ubicacionfisica=instance.id)
            for attr, value in detalle_data.items():
                setattr(detalle, attr, value)
            detalle.save()
        return instance


class StatusSerializer(serializers.Serializer):
    estatus = serializers.CharField(max_length=255, allow_blank=False)


class AssignUserSerializer(serializers.Serializer):
    user_id = serializers.IntegerField()

    def validate_user_id(self, value):
        user_model = get_user_model()
        if not user_model.objects.filter(id=value).exists():
            raise serializers.ValidationError("User does not exist.")
        return value


class UserSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = get_user_model()
        fields = ["id", "username", "first_name", "last_name", "email", "is_active"]
