# Etapa 1: Construcción
# Usa una imagen base oficial de Python sobre Alpine Linux. Es extremadamente ligera.
FROM python:3.13.5-alpine3.22 as builder

# Establece el directorio de trabajo en /app
WORKDIR /app

# Instala dependencias del sistema necesarias para compilar paquetes de Python con extensiones C.
# build-base es el equivalente a build-essential en Debian.
# sqlite-dev puede ser necesario para compilar algunas librerías que interactúan con SQLite.
RUN apk add --no-cache build-base sqlite-dev

# Copia solo el archivo de dependencias para aprovechar el cache de Docker
COPY requirements.txt .

# Descarga y compila las dependencias de Python como "wheels"
RUN pip wheel --no-cache-dir --wheel-dir /app/wheels -r requirements.txt

# Etapa 2: Producción
FROM python:3.13.5-alpine3.22

WORKDIR /app
COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .
RUN pip install --no-cache-dir --no-index --find-links=/wheels -r requirements.txt && rm -rf /wheels

# Copia el código de la aplicación al directorio de trabajo
COPY . .

# Expone el puerto 8000 para que la API sea accesible
EXPOSE 8000

# Comando para ejecutar la aplicación.
# Uvicorn es un servidor ASGI de alto rendimiento.
# --host 0.0.0.0 es crucial para que sea accesible desde fuera del contenedor.
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
