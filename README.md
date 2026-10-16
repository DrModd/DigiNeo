# DigiNeo

Образ сетевого стримера для DIY-усилителя **DigiD D1** на базе **NanoPi NEO3** (Rockchip RK3328).
Приватная личная сборка.

## Атрибуция
Собран на основе прошивки **Pure для NEO3** (автор **ppy2**, puredsd.ru) — закрытая прошивка.
DigiNeo — адаптация под усилитель DigiD D1 (STM32 + AX5689 + AK4137), по линии
DigiFox/PureFox. Сторонние компоненты (MPD, upmpdcli, Roon Bridge, shairport-sync,
raspotify, tidalconnect и др.) — под своими лицензиями их авторов.

## Что внутри
- меню **Fox Remote** (http://digineo.local), классическое — на classic.php;
- Android-пульт **[FoxRemoteN](https://github.com/DrModd/FoxRemoteN)** находит плату автоматически (mDNS: MPD анонсируется как «DigiNeo (DigiFox) MPD»);
- Qobuz: **нативный Qobuz Connect впечён** (устройство «DigiNeo» в приложении Qobuz; UPnP через upmpdcli как запасной путь), PCM битперфект до 192 кГц, DSD→PCM;
- Wi-Fi: в меню «Усилитель, будильник, таймер» → Wi-Fi (поиск сетей и подключение, нужен USB-свисток);
- Roon, AirPlay, Spotify, Tidal, HQPlayer NAA (`networkaudiod`); плеер squeezelite;
- связь с усилителем по UART1 (протокол pf_link), режим USB→I2S;
- вход SSH: **root / digineo** (сменить: `passwd`).
Убрано для лёгкости: LMS/Squeezebox-сервер, MinimServer, Scream, второе ядро 6.1.11.
Размер образа ~2,79 ГиБ.

## Сборка файла и запись (Windows)
1. Скачать папку: **Code → Download ZIP**.
2. В папке `image` дважды кликнуть **join_windows.bat** → соберётся `DigiNeo.zip`.
3. balenaEtcher → `DigiNeo.zip` → карта → Flash.
Контроль: склеенный `DigiNeo.zip` должен весить **1361694478** байт.
SHA-256: `11baf6380cbcf9fcb0eb962283cc7adbbf12250543c72744b29c274c86ca3188`
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
