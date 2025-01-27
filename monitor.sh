#!/bin/bash

# Настройка переменных окружения
export tgApiQn=""
export tgIdQn=""
export address=""

# URL endpoints
brnUrl="https://brn.explorer.caldera.xyz/api?module=account&action=balance&address=${address}"
arbtUrl="https://arbitrum-sepolia.blockscout.com/api?module=account&action=balance&address=${address}"
blssUrl="https://blast-testnet.blockscout.com/api?module=account&action=balance&address=${address}"
bsspUrl="https://base-sepolia.blockscout.com/api?module=account&action=balance&address=${address}"
opspUrl="https://optimism-sepolia.blockscout.com/api?module=account&action=balance&address=${address}"

# URL для explorer
brnUrlEx="https://brn.explorer.caldera.xyz/address/${address}"
arbtUrlEx="https://arbitrum-sepolia.blockscout.com/address/${address}"
blssUrlEx="https://blast-testnet.blockscout.com/address/${address}"
bsspUrlEx="https://base-sepolia.blockscout.com/address/${address}"
opspUrlEx="https://optimism-sepolia.blockscout.com/address/${address}"

mega=$(echo 10/10^19 | bc -l)

# Проверка Telegram бота
msgTg=$(echo -e "<b>[ ИНФО ]</b> Telegram бот авторизован!")
tgTest=$(curl -s -X POST "https://api.telegram.org/bot${tgApiQn}/sendMessage" -d chat_id="${tgIdQn}" -d text="${msgTg}" -d parse_mode="HTML" | grep 'error_code')
if [ -n "${tgTest}" ]; then
    echo -e "[ ОШИБКА ] Ошибка авторизации!\nПроверьте API ключ и ID чата, убедитесь что бот запущен"
    exit 1
fi

# Функции получения балансов
function brnFetch() {
    brnBal=$(curl -s $brnUrl | jq -r .result)
    brnBal=$(bc <<< "$brnBal * $mega")
    brnBalRound=$(echo $brnBal | sed "s/\..*//g")
    brnBalFloat=$(echo $brnBal | sed "s/.*[.]//g" | cut -c1-2)
    brnBal=$(echo "$brnBalRound.$brnBalFloat")
}

function arbtFetch() {
    arbtBal=$(curl -s $arbtUrl | jq -r .result)
    arbtBal=$(bc <<< "$arbtBal * $mega")
    arbtBalRound=$(echo $arbtBal | sed "s/\..*//g")
    arbtBalFloat=$(echo $arbtBal | sed "s/.*[.]//g" | cut -c1-2)
    arbtBal=$(echo "$arbtBalRound.$arbtBalFloat")
}

function blssFetch() {
    blssBal=$(curl -s $blssUrl | jq -r .result)
    blssBal=$(bc <<< "$blssBal * $mega")
    blssBalRound=$(echo $blssBal | sed "s/\..*//g")
    blssBalFloat=$(echo $blssBal | sed "s/.*[.]//g" | cut -c1-2)
    blssBal=$(echo "$blssBalRound.$blssBalFloat")
}

function bsspFetch() {
    bsspBal=$(curl -s $bsspUrl | jq -r .result)
    bsspBal=$(bc <<< "$bsspBal * $mega")
    bsspBalRound=$(echo $bsspBal | sed "s/\..*//g")
    bsspBalFloat=$(echo $bsspBal | sed "s/.*[.]//g" | cut -c1-2)
    bsspBal=$(echo "$bsspBalRound.$bsspBalFloat")
}

function opspFetch() {
    opspBal=$(curl -s $opspUrl | jq -r .result)
    opspBal=$(bc <<< "$opspBal * $mega")
    opspBalRound=$(echo $opspBal | sed "s/\..*//g")
    opspBalFloat=$(echo $opspBal | sed "s/.*[.]//g" | cut -c1-2)
    opspBal=$(echo "$opspBalRound.$opspBalFloat")
}

# Часовая сводка
function recap() {
    while true; do
        echo "[ИНФО] Запуск сводки ✅"
        brnFetch
        arbtFetch
        blssFetch
        bsspFetch
        opspFetch
        
        # Сохраняем неформатированные значения для подсчета
        raw_total=$(bc <<< "${arbtBal} + ${blssBal} + ${bsspBal} + ${opspBal}")
        raw_total_round=$(echo $raw_total | sed "s/\..*//g")
        raw_total_float=$(echo $raw_total | sed "s/.*[.]//g" | cut -c1-2)
        totalFirstEth="$raw_total_round.$raw_total_float"
        
        echo "[ИНФО] Общий баланс ETH: ${totalFirstEth} ETH"
        brnFirstBal=${brnBal}
        
        while sleep 3600; do
            ipAddr=$(curl -s https://api.ipify.org)
            status=$(ps aux | grep -c executor)
            
            if [ $status -gt 1 ]; then
                status="✅ Активен \\\| Запущен"
            else
                status="⚠️ Неактивен"
            fi
            
            # Получение текущих балансов
            brnFetch
            arbtFetch
            blssFetch
            bsspFetch
            opspFetch
            
            # Сначала считаем общий баланс
            total_eth=$(bc <<< "${arbtBal} + ${blssBal} + ${bsspBal} + ${opspBal}")
            total_eth_round=$(echo $total_eth | sed "s/\..*//g")
            total_eth_float=$(echo $total_eth | sed "s/.*[.]//g" | cut -c1-2)
            total_eth_formatted="$total_eth_round.$total_eth_float"
            
            # Форматирование для Telegram
            brnBal=$(echo $brnBal | sed "s/\./\\\./g")
            arbtBal=$(echo $arbtBal | sed "s/\./\\\./g")
            blssBal=$(echo $blssBal | sed "s/\./\\\./g")
            bsspBal=$(echo $bsspBal | sed "s/\./\\\./g")
            opspBal=$(echo $opspBal | sed "s/\./\\\./g")
            total_eth_formatted=$(echo $total_eth_formatted | sed "s/\./\\\./g")
            
            # Формирование красивого сообщения
            recapMsg=$(echo -e "\
🔄 *ЧАСОВАЯ СВОДКА* 🔄\n\
━━━━━━━━━━━━━━━━━━━━\n\
\n\
🖥 *Системная информация*\n\
└ IP: \`${ipAddr}\`\n\
└ Статус: ${status}\n\
\n\
💼 *Информация о кошельке*\n\
└ Адрес: \`${address}\`\n\
\n\
💰 *Балансы ETH*\n\
├ Arbitrum: [${arbtBal}](${arbtUrlEx})\n\
├ Blast: [${blssBal}](${blssUrlEx})\n\
├ Base: [${bsspBal}](${bsspUrlEx})\n\
├ Optimism: [${opspBal}](${opspUrlEx})\n\
└ *Общий баланс:* ${total_eth_formatted} ETH\n\
\n\
🌟 *Баланс BRN*\n\
└ [${brnBal}](${brnUrlEx})\n\
\n\
━━━━━━━━━━━━━━━━━━━━\n\
🤖 Monitor v1\.0")
            
            echo -e "\n[ИНФО] Отправка сообщения в Telegram... ⏳"
            curl -s -X POST "https://api.telegram.org/bot${tgApiQn}/sendMessage" \
                -d chat_id="${tgIdQn}" \
                -d text="${recapMsg}" \
                -d parse_mode="MarkdownV2"
            echo -e "[ИНФО] Сообщение отправлено ✅"
        done
    done
}

# Основной процесс проверки каждые 5 минут
function mainProcess() {
    brnFetch
    formatted_brnBal=$(echo $brnBal | sed "s/\./\\\./g")
    msgTg=$(echo -e "Начальный баланс: _${formatted_brnBal}_")
    
    curl -s -X POST "https://api.telegram.org/bot${tgApiQn}/sendMessage" \
        -d chat_id="${tgIdQn}" \
        -d text="${msgTg}" \
        -d parse_mode="MarkdownV2"
    
    # Сохраняем начальное значение для сравнения (неформатированное!)
    oldBal=$brnBal
    
    while true; do
        sleep 300
        brnFetch
        
        # Используем неформатированные значения для сравнения
        if (( $(echo "$brnBal > $oldBal" | bc -l) )); then
            difference=$(echo "$brnBal - $oldBal" | bc -l)
            
            # Форматируем значения только для вывода
            formatted_brnBal=$(echo $brnBal | sed "s/\./\\\./g")
            formatted_difference=$(echo $difference | sed "s/\./\\\./g")
            
            echo -e "[ИНФО] Баланс увеличился на $difference"
            echo -e "[ИНФО] Текущий баланс: $brnBal"
            
            msgTg=$(echo -e "Баланс увеличился на *${formatted_difference}*\\nТекущий баланс: _${formatted_brnBal}_")
            curl -s -X POST "https://api.telegram.org/bot${tgApiQn}/sendMessage" \
                -d chat_id="${tgIdQn}" \
                -d text="${msgTg}" \
                -d parse_mode="MarkdownV2"
            
            # Обновляем старое значение (неформатированное!)
            oldBal=$brnBal
        else
            echo -e "Текущий баланс: $brnBal, изменений нет..."
        fi
    done
}

# Запуск обоих процессов
mainProcess & recap
