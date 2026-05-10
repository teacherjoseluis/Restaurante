from django.core.exceptions import ObjectDoesNotExist
from django.db import IntegrityError
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import exception_handler


class ConflictError(Exception):
    """Domain operation cannot be completed because persisted state conflicts."""


def api_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None:
        return response

    if isinstance(exc, ObjectDoesNotExist):
        return Response(
            {"detail": "Resource not found."},
            status=status.HTTP_404_NOT_FOUND,
        )

    if isinstance(exc, (ValueError,)):
        return Response(
            {"detail": str(exc)},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if isinstance(exc, (ConflictError, IntegrityError)):
        return Response(
            {"detail": str(exc)},
            status=status.HTTP_409_CONFLICT,
        )

    return None
