from django.conf import settings
from django.db import models


class SucursalSistema(models.Model):
    id = models.AutoField(db_column="ID", primary_key=True)
    nombre = models.TextField(db_column="Nombre", blank=True)
    direccion = models.TextField(db_column="Direccion", blank=True)
    personacontacto = models.CharField(db_column="PersonaContacto", max_length=255, blank=True)
    telefono1 = models.CharField(db_column="Telefono1", max_length=255, blank=True)
    telefono2 = models.CharField(db_column="Telefono2", max_length=255, blank=True)
    telefono3 = models.CharField(db_column="Telefono3", max_length=255, blank=True)
    correoelectronico = models.CharField(db_column="CorreoElectronico", max_length=255, blank=True)
    id_cliente = models.IntegerField(db_column="ID_Cliente", blank=True, null=True)
    identificadorcorto = models.CharField(db_column="IdentificadorCorto", max_length=3, blank=True)

    class Meta:
        db_table = "Sucursal_Sistema"
        ordering = ["id"]

    def __str__(self):
        return self.nombre


class CatalogoClasificacion(models.Model):
    id = models.AutoField(db_column="ID", primary_key=True)
    nombreclasificacion = models.CharField(db_column="NombreClasificacion", max_length=255, blank=True)
    estatus = models.CharField(db_column="Estatus", max_length=255, blank=True)

    class Meta:
        db_table = "Catalogo_Clasificacion"
        ordering = ["id"]

    def __str__(self):
        return self.nombreclasificacion


class UnidadMedida(models.Model):
    id = models.AutoField(db_column="ID", primary_key=True)
    unidadmedida = models.CharField(db_column="UnidadMedida", max_length=255, blank=True)

    class Meta:
        db_table = "Unidad_Medida"
        ordering = ["id"]

    def __str__(self):
        return self.unidadmedida


class Presentacion(models.Model):
    id = models.AutoField(db_column="ID", primary_key=True)
    nombrepresentacion = models.CharField(db_column="NombrePresentacion", max_length=255, blank=True)
    tipo = models.CharField(db_column="Tipo", max_length=255, blank=True)

    class Meta:
        db_table = "Presentacion"
        ordering = ["id"]

    def __str__(self):
        return self.nombrepresentacion


class TipoCuentaContable(models.Model):
    id = models.AutoField(db_column="ID", primary_key=True)
    nombre = models.CharField(db_column="Nombre", max_length=255, blank=True)
    estatus = models.CharField(db_column="Estatus", max_length=255, blank=True)

    class Meta:
        db_table = "Tipo_CuentaContable"
        ordering = ["id"]

    def __str__(self):
        return self.nombre


class UbicacionFisica(models.Model):
    id = models.AutoField(db_column="ID", primary_key=True)
    id_sucursalsistema = models.IntegerField(db_column="Id_SucursalSistema", blank=True, null=True)
    nombre = models.CharField(db_column="Nombre", max_length=255, blank=True)
    descripcion = models.TextField(db_column="Descripcion", blank=True)
    tipo = models.CharField(db_column="Tipo", max_length=255, blank=True)
    id_subcuentacontable = models.IntegerField(
        db_column="Id_SubCuentaContable",
        blank=True,
        null=True,
    )
    estatus = models.CharField(db_column="Estatus", max_length=255, blank=True, default="A")
    cuenta_contable = models.IntegerField(db_column="Cuenta_Contable", blank=True, null=True)

    class Meta:
        db_table = "Ubicacion_Fisica"
        ordering = ["id"]

    def __str__(self):
        return self.nombre


class DetalleUbicacion(models.Model):
    id = models.AutoField(db_column="ID", primary_key=True)
    id_ubicacionfisica = models.IntegerField(db_column="ID_UbicacionFisica", db_index=True)
    direccion = models.TextField(db_column="Direccion", blank=True)
    telefono = models.CharField(db_column="Telefono", max_length=255, blank=True)
    horariorecepcion = models.CharField(db_column="HorarioRecepcion", max_length=255, blank=True)
    saldoactual = models.IntegerField(db_column="SaldoActual", blank=True, null=True)
    impresora = models.CharField(db_column="Impresora", max_length=255, blank=True)
    terminalsalida = models.CharField(db_column="TerminalSalida", max_length=255, blank=True)
    minimocomensales = models.CharField(db_column="MinimoComensales", max_length=255, blank=True)
    maximocomensales = models.CharField(db_column="MaximoComensales", max_length=255, blank=True)
    tipo = models.CharField(db_column="Tipo", max_length=255, blank=True)

    class Meta:
        db_table = "Detalle_Ubicacion"
        ordering = ["id"]


class DetalleDocumento(models.Model):
    id = models.AutoField(db_column="ID", primary_key=True)
    id_ubicacionfisica1 = models.IntegerField(db_column="Id_UbicacionFisica1", blank=True, null=True)
    id_ubicacionfisica2 = models.IntegerField(db_column="Id_UbicacionFisica2", blank=True, null=True)
    estatus = models.CharField(db_column="Estatus", max_length=255, blank=True)

    class Meta:
        db_table = "Detalle_Documento"


class LibroCuentaContable(models.Model):
    id = models.AutoField(db_column="ID", primary_key=True)
    saldo = models.IntegerField(db_column="Saldo", blank=True, null=True)
    id_cuentacontable = models.IntegerField(db_column="ID_CuentaContable", blank=True, null=True)

    class Meta:
        db_table = "Libro_CuentaContable"


class AuthUserUbicacionFisica(models.Model):
    id = models.AutoField(db_column="ID", primary_key=True)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        db_column="id_usuario",
        on_delete=models.CASCADE,
        related_name="ubicaciones_fisicas",
    )
    ubicacionfisica = models.ForeignKey(
        UbicacionFisica,
        db_column="id_ubicacionfisica",
        on_delete=models.CASCADE,
        related_name="usuarios_asignados",
    )

    class Meta:
        db_table = "AuthUser_UbicacionFisica"
        constraints = [
            models.UniqueConstraint(
                fields=["user", "ubicacionfisica"],
                name="unique_user_ubicacionfisica",
            )
        ]
