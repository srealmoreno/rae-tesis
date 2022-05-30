# RAE Tesis Repo

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/59b9bbbcc6ab43b985c261731b0ff639)](https://www.codacy.com/gh/srealmoreno/rae-tesis/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=srealmoreno/rae-tesis&amp;utm_campaign=Badge_Grade)

Este repositorio contiene los recursos necesarios para la elaboración de
las prácticas de la asignatura Redes de Area Extensa.

## Requisitos 📋

- Sistema operativo: Ubuntu o derivados
  - Focal 20.0 (LTS)
  - Bionic 18.04 (LTS)
  - Xenial 16.04 (LTS)
- Conexión a Internet.
- apt como gestor de paquetes.

### Alternativas 📋

Si tu sistema operativo no es Ubuntu o derivado, puedes echar un vistazo a nuestra
[Wiki](https://github.com/srealmoreno/rae-tesis/wiki/alternativas-instalacion)
para ver las alternativas.

### Instalación 🔧

[![Ubuntu script install - tests](https://github.com/srealmoreno/rae-tesis/actions/workflows/rae-ubuntu-install.yml/badge.svg)](https://github.com/srealmoreno/rae-tesis/actions/workflows/rae-ubuntu-install.yml)

Descarga el script de instalación:

Descargar desde línea de ordenes:

```bash
wget https://raw.githubusercontent.com/srealmoreno/rae-tesis/main/scripts/rae-ubuntu-install.sh
```

Dar permisos de ejecución

```bash
chmod +x rae-ubuntu-install.sh
```

Ejecución del script

```bash
sudo ./rae-ubuntu-install.sh
```

Para ver ayuda -h (help en inglés)

```bash
sudo ./rae-ubuntu-install.sh -h
```

## Docker 🐳

[![Docker image ci](https://github.com/srealmoreno/rae-tesis/actions/workflows/docker-image.yml/badge.svg)](https://github.com/srealmoreno/rae-tesis/actions/workflows/docker-image.yml)

Puedes echar un vistazo al archivo [dockerfile](../docker/dockerfile) para ver
como se construye el contenedor. Si hace falta una utilidad puedes solicitarla
abriendo una [issue](https://github.com/srealmoreno/rae-tesis/issues/new/choose)
en el repositorio.

## Wiki 📖

Puedes encontrar mucho más de cómo utilizar este proyecto en nuestra [Wiki](https://github.com/srealmoreno/rae-tesis/wiki)

## Autores ✒️

- **Salvador Real** [srealmoreno](https://github.com/srealmoreno)
- **Lester Stayner** [LesterVega](https://github.com/LesterVega)
- **Omar Ezequiel** [OmarRizo](https://github.com/OmarRizo)

También puedes mirar la lista de todos los [contribuyentes](https://github.com/srealmoreno/rae-tesis/contributors)
quíenes han participado en este proyecto.

## Licencia 📄

Este proyecto está bajo la Licencia GNU General Public License v3.0 - mira el archivo
[LICENSE.md](LICENSE.md) para más detalles

## Expresiones de Gratitud 🎁

- Damos gracias a nuestro Tutor **Aldo Rene** 😊.
