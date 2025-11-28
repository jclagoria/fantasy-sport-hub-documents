#!/bin/bash

# Título del script
echo "================================="
echo "  🧹 LIMPIADOR DE DOCKER 🧹  "
echo "================================="

# Preguntar confirmación
read -p "⚠️  ¿Estás seguro de que quieres limpiar TODO en Docker? (s/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]
then
    echo "Operación cancelada."
    exit 1
fi

# Detener todos los contenedores en ejecución
echo -e "\n🔴 Deteniendo todos los contenedores en ejecución..."
docker stop $(docker ps -aq) 2>/dev/null || echo "No hay contenedores en ejecución"

# Eliminar todos los contenedores
echo -e "\n🗑️  Eliminando todos los contenedores..."
docker rm -f $(docker ps -aq) 2>/dev/null || echo "No hay contenedores para eliminar"

# Eliminar todas las redes no utilizadas
echo -e "\n🌐 Eliminando redes no utilizadas..."
docker network prune -f

# Eliminar todos los volúmenes no utilizados
echo -e "\n💾 Eliminando volúmenes no utilizados..."
docker volume prune -f

# Eliminar todas las imágenes no utilizadas
echo -e "\n🖼️  Eliminando imágenes no utilizadas..."
docker image prune -af

# Limpiar el sistema de Docker (elimina datos no utilizados)
echo -e "\n🧹 Limpiando el sistema de Docker..."
docker system prune -af --volumes

# Mostrar estado actual
echo -e "\n✅ Limpieza completada. Estado actual:"
echo "================================="
docker ps -a
echo -e "\n🔹 Redes:"
docker network ls
echo -e "\n🔹 Volúmenes:"
docker volume ls
echo -e "\n🔹 Imágenes:"
docker images
