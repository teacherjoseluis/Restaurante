# Generated manually to keep the first API slice reproducible in tests.
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="CatalogoClasificacion",
            fields=[
                ("id", models.AutoField(db_column="ID", primary_key=True, serialize=False)),
                (
                    "nombreclasificacion",
                    models.CharField(blank=True, db_column="NombreClasificacion", max_length=255),
                ),
                ("estatus", models.CharField(blank=True, db_column="Estatus", max_length=255)),
            ],
            options={
                "db_table": "Catalogo_Clasificacion",
                "ordering": ["id"],
            },
        ),
        migrations.CreateModel(
            name="DetalleDocumento",
            fields=[
                ("id", models.AutoField(db_column="ID", primary_key=True, serialize=False)),
                (
                    "id_ubicacionfisica1",
                    models.IntegerField(blank=True, db_column="Id_UbicacionFisica1", null=True),
                ),
                (
                    "id_ubicacionfisica2",
                    models.IntegerField(blank=True, db_column="Id_UbicacionFisica2", null=True),
                ),
                ("estatus", models.CharField(blank=True, db_column="Estatus", max_length=255)),
            ],
            options={
                "db_table": "Detalle_Documento",
            },
        ),
        migrations.CreateModel(
            name="DetalleUbicacion",
            fields=[
                ("id", models.AutoField(db_column="ID", primary_key=True, serialize=False)),
                (
                    "id_ubicacionfisica",
                    models.IntegerField(db_column="ID_UbicacionFisica", db_index=True),
                ),
                ("direccion", models.TextField(blank=True, db_column="Direccion")),
                ("telefono", models.CharField(blank=True, db_column="Telefono", max_length=255)),
                (
                    "horariorecepcion",
                    models.CharField(blank=True, db_column="HorarioRecepcion", max_length=255),
                ),
                ("saldoactual", models.IntegerField(blank=True, db_column="SaldoActual", null=True)),
                ("impresora", models.CharField(blank=True, db_column="Impresora", max_length=255)),
                (
                    "terminalsalida",
                    models.CharField(blank=True, db_column="TerminalSalida", max_length=255),
                ),
                (
                    "minimocomensales",
                    models.CharField(blank=True, db_column="MinimoComensales", max_length=255),
                ),
                (
                    "maximocomensales",
                    models.CharField(blank=True, db_column="MaximoComensales", max_length=255),
                ),
                ("tipo", models.CharField(blank=True, db_column="Tipo", max_length=255)),
            ],
            options={
                "db_table": "Detalle_Ubicacion",
                "ordering": ["id"],
            },
        ),
        migrations.CreateModel(
            name="LibroCuentaContable",
            fields=[
                ("id", models.AutoField(db_column="ID", primary_key=True, serialize=False)),
                ("saldo", models.IntegerField(blank=True, db_column="Saldo", null=True)),
                (
                    "id_cuentacontable",
                    models.IntegerField(blank=True, db_column="ID_CuentaContable", null=True),
                ),
            ],
            options={
                "db_table": "Libro_CuentaContable",
            },
        ),
        migrations.CreateModel(
            name="Presentacion",
            fields=[
                ("id", models.AutoField(db_column="ID", primary_key=True, serialize=False)),
                (
                    "nombrepresentacion",
                    models.CharField(blank=True, db_column="NombrePresentacion", max_length=255),
                ),
                ("tipo", models.CharField(blank=True, db_column="Tipo", max_length=255)),
            ],
            options={
                "db_table": "Presentacion",
                "ordering": ["id"],
            },
        ),
        migrations.CreateModel(
            name="SucursalSistema",
            fields=[
                ("id", models.AutoField(db_column="ID", primary_key=True, serialize=False)),
                ("nombre", models.TextField(blank=True, db_column="Nombre")),
                ("direccion", models.TextField(blank=True, db_column="Direccion")),
                (
                    "personacontacto",
                    models.CharField(blank=True, db_column="PersonaContacto", max_length=255),
                ),
                ("telefono1", models.CharField(blank=True, db_column="Telefono1", max_length=255)),
                ("telefono2", models.CharField(blank=True, db_column="Telefono2", max_length=255)),
                ("telefono3", models.CharField(blank=True, db_column="Telefono3", max_length=255)),
                (
                    "correoelectronico",
                    models.CharField(blank=True, db_column="CorreoElectronico", max_length=255),
                ),
                ("id_cliente", models.IntegerField(blank=True, db_column="ID_Cliente", null=True)),
                (
                    "identificadorcorto",
                    models.CharField(blank=True, db_column="IdentificadorCorto", max_length=3),
                ),
            ],
            options={
                "db_table": "Sucursal_Sistema",
                "ordering": ["id"],
            },
        ),
        migrations.CreateModel(
            name="TipoCuentaContable",
            fields=[
                ("id", models.AutoField(db_column="ID", primary_key=True, serialize=False)),
                ("nombre", models.CharField(blank=True, db_column="Nombre", max_length=255)),
                ("estatus", models.CharField(blank=True, db_column="Estatus", max_length=255)),
            ],
            options={
                "db_table": "Tipo_CuentaContable",
                "ordering": ["id"],
            },
        ),
        migrations.CreateModel(
            name="UbicacionFisica",
            fields=[
                ("id", models.AutoField(db_column="ID", primary_key=True, serialize=False)),
                (
                    "id_sucursalsistema",
                    models.IntegerField(blank=True, db_column="Id_SucursalSistema", null=True),
                ),
                ("nombre", models.CharField(blank=True, db_column="Nombre", max_length=255)),
                ("descripcion", models.TextField(blank=True, db_column="Descripcion")),
                ("tipo", models.CharField(blank=True, db_column="Tipo", max_length=255)),
                (
                    "id_subcuentacontable",
                    models.IntegerField(blank=True, db_column="Id_SubCuentaContable", null=True),
                ),
                (
                    "estatus",
                    models.CharField(blank=True, db_column="Estatus", default="A", max_length=255),
                ),
                (
                    "cuenta_contable",
                    models.IntegerField(blank=True, db_column="Cuenta_Contable", null=True),
                ),
            ],
            options={
                "db_table": "Ubicacion_Fisica",
                "ordering": ["id"],
            },
        ),
        migrations.CreateModel(
            name="UnidadMedida",
            fields=[
                ("id", models.AutoField(db_column="ID", primary_key=True, serialize=False)),
                (
                    "unidadmedida",
                    models.CharField(blank=True, db_column="UnidadMedida", max_length=255),
                ),
            ],
            options={
                "db_table": "Unidad_Medida",
                "ordering": ["id"],
            },
        ),
        migrations.CreateModel(
            name="AuthUserUbicacionFisica",
            fields=[
                ("id", models.AutoField(db_column="ID", primary_key=True, serialize=False)),
                (
                    "ubicacionfisica",
                    models.ForeignKey(
                        db_column="id_ubicacionfisica",
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="usuarios_asignados",
                        to="restaurante.ubicacionfisica",
                    ),
                ),
                (
                    "user",
                    models.ForeignKey(
                        db_column="id_usuario",
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="ubicaciones_fisicas",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                "db_table": "AuthUser_UbicacionFisica",
            },
        ),
        migrations.AddConstraint(
            model_name="authuserubicacionfisica",
            constraint=models.UniqueConstraint(
                fields=("user", "ubicacionfisica"),
                name="unique_user_ubicacionfisica",
            ),
        ),
    ]
