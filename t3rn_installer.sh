#!/bin/bash

# =============================
# Логирование
# =============================
LOG_FILE="/var/log/t3rn_installer.log"

# Создаем файл логов и перенаправляем вывод
exec > >(tee -a $LOG_FILE) 2>&1

# Функции логирования
log_info() {
  echo -e "\e[32m[INFO]\e[0m $1"
}

log_warn() {
  echo -e "\e[33m[WARNING]\e[0m $1"
}

log_error() {
  echo -e "\e[31m[ERROR]\e[0m $1"
}

# =============================
# ASCII арт и старт скрипта
# =============================
echo -e '\e[35m\e[49m'
echo -e '                                                                                      '
echo -e '   ▄████████    ▄█    █▄       ▄████████ ▀█████████▄   ▄█       ▄██   ▄      ▄████████'
echo -e '  ███    ███   ███    ███     ███    ███   ███    ███ ███       ███   ██▄   ███    ███'
echo -e '  ███    █▀    ███    ███     ███    ███   ███    ███ ███       ███▄▄▄███   ███    ███'
echo -e '  ███         ▄███▄▄▄▄███▄▄   ███    ███  ▄███▄▄▄██▀  ███       ▀▀▀▀▀▀███   ███    ███'
echo -e '▀███████████ ▀▀███▀▀▀▀███▀  ▀███████████ ▀▀███▀▀▀██▄  ███       ▄██   ███ ▀███████████'
echo -e '         ███   ███    ███     ███    ███   ███    ██▄ ███       ███   ███   ███    ███'
echo -e '   ▄█    ███   ███    ███     ███    ███   ███    ███ ███▌    ▄ ███   ███   ███    ███'
echo -e ' ▄████████▀    ███    █▀      ███    █▀  ▄█████████▀  █████▄▄██  ▀█████▀    ███    █▀ '
echo -e '                                                      ▀\t\t\t\t       '
echo -e '                                                    \t\t\t       '
echo -e '\e[0m'

log_info "Начало установки T3RN Node Installer"

# =============================
# Создание папки и скачивание релиза
# =============================
log_info "Создаем директорию для установки..."
mkdir t3rn
cd t3rn || { log_error "Не удалось перейти в директорию t3rn."; exit 1; }

log_info "Скачиваем релиз версии v0.41.0..."
wget https://github.com/t3rn/executor-release/releases/download/v0.43.0/executor-linux-v0.43.0.tar.gz || {
  log_error "Не удалось скачать релиз версии v0.41.0."; exit 1;
}

log_info "Распаковываем архив..."
tar -xzf executor-linux-v0.43.0.tar.gz || { log_error "Ошибка при распаковке архива."; exit 1; }

log_info "Переходим в директорию бинарных файлов..."
cd executor/executor/bin || { log_error "Не удалось перейти в директорию бинарных файлов."; exit 1; }


# =============================
# Проверка и создание директории для логов
# =============================
log_info "Проверяем и создаем директорию для логов..."
LOG_DIR="/root/t3rn/executor/logs"
if [ ! -d "$LOG_DIR" ]; then
  log_info "Директория для логов не найдена, создаем..."
  mkdir -p "$LOG_DIR" || { log_error "Не удалось создать директорию для логов."; exit 1; }
else
  log_info "Директория для логов уже существует."
fi

# =============================
# Запрос ключа от пользователя
# =============================
log_info "Введите свой PRIVATE_KEY_LOCAL:"
read -p "PRIVATE_KEY_LOCAL: " PRIVATE_KEY_LOCAL

# =============================
# Запрос RPC для разных сетей
# =============================
log_info "Введите RPC для arbitrum-sepolia:"
read -p "RPC for arbitrum-sepolia: " RPC_ARBITRUM
log_info "Введите RPC для base-sepolia:"
read -p "RPC for base-sepolia: " RPC_BASE
log_info "Введите RPC для blast-sepolia:"
read -p "RPC for blast-sepolia: " RPC_BLAST
log_info "Введите RPC для optimism-sepolia:"
read -p "RPC for optimism-sepolia: " RPC_OPTIMISM

# =============================
# Создание сервисного файла
# =============================
log_info "Создаем systemd сервисный файл..."
cat <<EOF > /etc/systemd/system/executor.service
[Unit]
Description=Executor Service
After=network.target

[Service]
ExecStart=/root/t3rn/executor/executor/bin/executor
WorkingDirectory=/root/t3rn/executor/executor/bin
Environment="NODE_ENV=testnet"
Environment="LOG_LEVEL=debug"
Environment="LOG_PRETTY=false"
Environment="EXECUTOR_PROCESS_ORDERS=true"
Environment="EXECUTOR_PROCESS_CLAIMS=true"
Environment="ENABLED_NETWORKS=arbitrum-sepolia,base-sepolia,blast-sepolia,optimism-sepolia,l1rn"
Environment="EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false"
Environment="EXECUTOR_MAX_L3_GAS_PRICE=500"
Environment="EXECUTOR_ENABLE_BATCH_BIDDING=false"
Environment="PRIVATE_KEY_LOCAL=$PRIVATE_KEY_LOCAL"
Environment="ENABLED_NETWORKS=arbitrum-sepolia,base-sepolia,blast-sepolia,optimism-sepolia,l1rn"
Environment="RPC_ENDPOINTS_ARBT=$RPC_ARBITRUM"
Environment="RPC_ENDPOINTS_BSSP=$RPC_BASE"
Environment="RPC_ENDPOINTS_BLSS=$RPC_BLAST"
Environment="RPC_ENDPOINTS_OPSP=$RPC_OPTIMISM"
Restart=always
RestartSec=5
StandardOutput=append:/root/t3rn/executor/logs/executor.log
StandardError=append:/root/t3rn/executor/logs/executor-error.log
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

log_info "Перезагружаем systemd и активируем сервис..."
systemctl daemon-reload
systemctl enable executor
systemctl start executor || { log_error "Не удалось запустить сервис."; exit 1; }

log_info "Установка завершена успешно!"
