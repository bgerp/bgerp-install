#!/usr/bin/env bash
#
# Скрипт за Ubuntu/Mint, който:
#  1) Обновява системата
#  2) Инсталира FFmpeg + нужните кодеци
#  3) Автоматично открива и инсталира подходящ видео драйвер за NVIDIA/AMD
#  4) Инсталира допълнителни пакети за хардуерно ускорение (cuda, vaapi и др.)

set -e

echo "=== 1) Обновяване на системата и пакетите ==="
sudo apt-get update -y
sudo apt-get upgrade -y

echo "=== 2) Инсталиране на FFmpeg и допълнителни кодеци ==="
#sudo apt-get install -y ffmpeg ubuntu-restricted-extras libavcodec-extra
sudo apt-get install -y ffmpeg libavcodec-extra

echo "=== 3) Проверка за видеокарта и инсталиране на драйвери/библиотеки ==="

# Проверка за NVIDIA
if lspci | grep -qi nvidia; then
  echo "NVIDIA карта е открита."

  echo "Инсталиране на препоръчаните драйвери чрез 'ubuntu-drivers autoinstall'..."
  sudo ubuntu-drivers autoinstall

  # Инсталираме допълнителни пакети за CUDA/ENC/DEC (ако не са сложени от autoinstall):
  echo "Инсталиране на CUDA toolkit и NVENC/NVDEC библиотеки..."
  sudo apt-get install -y nvidia-cuda-toolkit libnvidia-encode-* libnvidia-decode-*

# Проверка за AMD
elif lspci | grep -qi amd; then
  echo "AMD карта е открита."

  # VAAPI/VDPAU драйвери
  sudo apt-get install -y mesa-va-drivers mesa-vdpau-drivers vainfo vdpauinfo

else
  echo "Не е открита NVIDIA или AMD карта. Пропускаме драйверите за GPU."
fi

echo "=== Инсталацията е завършена успешно! ==="
echo "=== Ако има нов инсталиран драйвер, направете рестарт преди да ползвате FFmpeg за хардуерно ускорение. ==="

