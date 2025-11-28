#!/bin/bash
# run-mongodb-init.sh

# Variables del entorno
MONGO_CONTAINER_NAME="mongodb-init-container"
NETWORK_NAME="mongodb_mongodb_network"

# Ejecutar el contenedor de MongoDB con el script de inicialización
docker run -d --rm \
  --name $MONGO_CONTAINER_NAME \
  --network $NETWORK_NAME \
  -v $(pwd)/init-mongo.js:/docker-entrypoint-initdb.d/init-mongo.js:ro \
  -e MONGO_INITDB_ROOT_USERNAME=$MONGO_INITDB_ROOT_USERNAME \
  -e MONGO_INITDB_ROOT_PASSWORD=$MONGO_INITDB_ROOT_PASSWORD \
  -e MONGO_INITDB_DATABASE=$MONGO_INITDB_DATABASE \
  mongo

# Esperar a que MongoDB esté listo
echo "Esperando a que MongoDB se inicie..."
sleep 5

# Verificar que el contenedor se ejecutó correctamente
if [ $? -eq 0 ]; then
  echo "Script de inicialización ejecutado correctamente"
  # Detener el contenedor después de la inicialización
  docker stop $MONGO_CONTAINER_NAME
else
  echo "Error al ejecutar el script de inicialización"
  exit 1
fi