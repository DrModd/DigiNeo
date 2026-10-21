# DigiNeo

Образ сетевого стримера для DIY-усилителя **DigiD D1** на базе **NanoPi NEO3** (Rockchip RK3328).
Личная сборка, опубликована с разрешения автора исходной прошивки.

## Атрибуция
Собран на основе прошивки **Pure для NEO3** (автор **ppy2**, puredsd.ru); выложен с разрешения автора.
DigiNeo — адаптация под усилитель DigiD D1 (STM32 + AX5689 + AK4137), по линии
DigiFox/PureFox. Сторонние компоненты (MPD, upmpdcli, Roon Bridge, shairport-sync,
raspotify, tidalconnect и др.) — под своими лицензиями их авторов.

## Что внутри
- меню **Fox Remote** (http://digineo.local), классическое — на classic.php;
- Android-пульт **[FoxRemoteN](https://github.com/DrModd/FoxRemoteN)** находит плату автоматически (mDNS: MPD анонсируется как «DigiNeo (DigiFox) MPD»);
- Qobuz: **нативный Qobuz Connect впечён** (устройство «DigiNeo» в приложении Qobuz; UPnP через upmpdcli как запасной путь), PCM битперфект до 192 кГц, DSD→PCM;
- Wi-Fi: в меню «Усилитель, будильник, таймер» → Wi-Fi (поиск сетей и подключение, нужен USB-свисток);
- **Яндекс Музыка** впечена (служба `ymusicd` собирается на плате при первой загрузке с интернетом; вход — страница «Яндекс Музыка» в меню);
- **онлайн-обновление** без перепрошивки: меню «Усилитель…» → Обновление (каталог [DigiNeo-updates](https://github.com/DrModd/DigiNeo-updates), версия образа 1.0.1);
- Roon, AirPlay, Spotify, Tidal, HQPlayer NAA (`networkaudiod`); плеер squeezelite;
- связь с усилителем по UART1 (протокол pf_link), режим USB→I2S;
- вход SSH: **root / digineo** (сменить: `passwd`).
Убрано для лёгкости: LMS/Squeezebox-сервер, MinimServer, Scream, второе ядро 6.1.11.
Размер образа ~2,79 ГиБ.

## Яндекс Музыка (extras/yandex-music)
Та же Яндекс Музыка, что в DigiFox: служба `ymusicd` (127.0.0.1:6601) + страница
`yandex.php` в меню Fox Remote. В образе уже есть: при первой загрузке с интернетом сама
соберётся `ymusicd` (журнал `/var/log/digineo-ymusic-build.log`). Ниже — ручная установка/обновление
скриптом на плате (нужен интернет):
```
scp -r extras/yandex-music root@digineo.local:/root/      # с компьютера, пароль digineo
ssh root@digineo.local
bash /root/yandex-music/install.sh                         # повторный запуск = обновление
```
Дальше: http://digineo.local/yandex.php → «Открыть вход Яндекса» → вставить адрес с `access_token=…`.
Служба: `systemctl status ymusicd`, журнал `journalctl -u ymusicd`. Удалить: `bash install.sh --remove`.

## Сборка файла и запись (Windows)
1. Скачать папку: **Code → Download ZIP**.
2. В папке `image` дважды кликнуть **join_windows.bat** → соберётся `DigiNeo.zip`.
3. balenaEtcher → `DigiNeo.zip` → карта → Flash.
Контроль: склеенный `DigiNeo.zip` должен весить **1361625904** байт.
SHA-256: `7d4e6d1d87e60658925e20e3a2051af19a1ed4f7eca13617bdf0f3dbcae16b8c`
(Linux/Mac: `sh join_linux_mac.sh`)

## Первый запуск
Воткнуть Ethernet (нужен интернет один раз) — сервис первой загрузки доустановит
toolchain и соберёт pfrate/uac2_router. Для USB→I2S — одна перезагрузка после.

## Провода (26-пин + USB2.0-гребёнка NEO3)
- UART1 к STM32: пины **8 (TX) / 10 (RX) / 6 (GND)**, 115200 8N1.
- I2S к AK4137/AX5689: **11 MCLK / 15 SCLK / 13 LRCK / 22 SDO / 14 GND**.
- USB→I2S (вход): D+ → **4**, D− → **6**, GND → **1** (VBUS не подключать).
- Wi-Fi-свисток → USB3.0 (драйверы rtl8xxxu / mt7601u / mt76).

## Нативный Qobuz Connect
Впечён в образ и работает сразу — ничего ставить не нужно. В приложении Qobuz
плата видна как устройство **DigiNeo** (Connect), рулится с телефона.

Как это сделано: бинарник Qobuz armhf собран под glibc 2.40 + OpenSSL 3, а база
DigiNeo — Debian 11 (glibc 2.31). Поэтому он запускается не на системном glibc,
а на своём рантайме (`/opt/qobuz-connect/rt`, снят из rootfs Фокса) через
собственный загрузчик — несовместимость обходится. Ядро 5.15.93 собрано с
`CONFIG_COMPAT=y` (32-бит armhf поддержан). Кнопка Qobuz и пульт FoxRemoteN
выбирают нативный Connect автоматически; если звук капризничает — UPnP (upmpdcli)
остаётся запасным путём.

## Лицензия
Собственный код и скрипты DigiNeo (каталог `extras`, установщики, README) — **GNU GPL v3**, см. `LICENSE` (Copyright (c) 2026 DrModd).
Лицензия не распространяется на образ целиком: в нём прошивка Pure (автор ppy2, выложена с его
разрешения) и сторонние компоненты (MPD, upmpdcli, shairport-sync и др.) — каждый под лицензией своего автора.
