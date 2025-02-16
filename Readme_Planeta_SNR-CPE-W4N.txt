Тема на форуме.
https://forum.planeta.tc/forums/weburg-tv/comp-tv/170803

Удалось запустить DLNA-сервер с поддержкой плейлиста в новом формате на роутере SNR-CPE-W4N.

К роутеру можно подключиться по SSH и запускать на нём сторонние программы. Первым (и, пожалуй, единственным) компактным DLNA-сервером с открытым исходным кодом является [URL="http://xupnpd.org/"]xupnpd[/URL] ([URL="https://github.com/clark15b/xupnpd"]репозиторий на GitHub[/URL]). Загрузил, собрал и запустил его сначала на ПК, поместил в его папку плейлист с http://ott.tv.planeta.tc/plst.m3u. Сервер выдаёт список каналов по категориям, VLC отображает его и воспроизводит их, а телевизор отображает список, но не воспроизводит, так как не поддерживает формат HLS. Нужен был сервер, который преобразовывал бы HLS в непрерывный видеопоток.

Оказалось, что у того же автора есть следующая версия сервера — [URL="http://xupnpd.org/xupnpd2_en.html"]xupnpd2[/URL]. Он также с открытым исходным кодом ([URL="https://github.com/clark15b/xupnpd2"]репозиторий на GitHub[/URL]) и свободен для частного использования. Запущенный на ПК, он выдаёт список каналов (правда, без категорий), и телевизор на этот раз воспроизводит их!

Нужно было собрать сервер под архитектуру MIPS (роутер построен на SoC Ralink RT3052). Единственный toolchain (набор компиляторов и библиотек) для сборки под MIPS, который я нашёл, оказался в составе OpenWRT. Он не предлагался для загрузки отдельно, да и краткой инструкции по его созданию не нашлось, поэтому пришлось следовать инструкции по сборке образа OpenWRT для совместимого роутера. Версию и файл конфигурации для конкретной модели роутера выбрал чуть ли не первые попавшиеся, сборка образа завершилась с ошибкой. Правда, toolchain к этому времени был уже готов, а для сборки сервера нужен был только он. Потребовалось сделать пару небольших правок в коде сервера, чтобы он собрался под MIPS. Однако на роутере он не запустился. Даже динамический линкер у него был glibc, а у программ на роутере — ld-uClibc.so.0.

Начал искать, как выбрать uClibc при создании прошивки и toolchain, выбрал, пересобрал их. Далее оказалось, что сервер требует несколько динамических библиотек, которых нет на роутере или их версии отличаются. Пробовал копировать их на роутер, загружать через LD_PRELOAD, но тщетно. Похоже ОС роутера не поддерживает такой возможности, и в лучшем случае сервер падал с SIGBUS.

[SPOILER="Инструкция для создания toolchain для сборки под MIPS."][URL="https://openwrt.org/docs/guide-developer/build-system/use-buildsystem"]https://openwrt.org/docs/guide-developer/build-system/use-buildsystem[/URL]

1. Загрузить код из репозитория OpenWRT
[B]git clone https://git.openwrt.org/openwrt/openwrt.git openwrt
cd openwrt
git pull[/B]
 
2. Выбрать ревизию
[B]git branch -a
git tag
git checkout v17.01.7[/B]

3. Обновить feeds
[B]./scripts/feeds update -a
./scripts/feeds install -a[/B]

4. Загрузить файл конфигурации для rt305x
[B]# OpenWrt 18.06 and before
wget https://downloads.openwrt.org/releases/17.01.7/targets/ramips/rt305x/config.seed -O .config[/B]

5. Начать сборку
[B]make[/B]

Через несколько секунд появится графическое меню.
Включить "Advanced configuration options (for developers)" -> "Show broken platforms / packages".
Выбрать "Use uClibc" в "Advanced configuration options (for developers)" -> "Toolchain Options" -> "C Library implementation".

Сборка продолжится, дожидаться создания образа не требуется. Важно, чтобы появились следующие файлы.

[B]staging_dir/toolchain-mipsel_24kc_gcc-5.4.0_uClibc-1.0.14/bin/mipsel-openwrt-linux-uclibc-gcc
staging_dir/toolchain-mipsel_24kc_gcc-5.4.0_uClibc-1.0.14/bin/mipsel-openwrt-linux-uclibc-strip
staging_dir/toolchain-mipsel_24kc_gcc-5.4.0_uClibc-1.0.14/lib/libm.a
staging_dir/toolchain-mipsel_24kc_gcc-5.4.0_uClibc-1.0.14/lib/libdl.a[/B]

[/SPOILER]

Далее попробовал собрать сервер статически, чтобы не требовались внешние библиотеки. Для этого потребовалось подключить пару статических библиотек из toolchain. Сервер собрался и запустился на роутере! В файле конфигурации сервера потребовалось задать правильные названия сетевых интерфейсов. Однако снаружи сервер не было видно. Проблема оказалась в том, что в iptables были закрыты все порты кроме нескольких. После добавления правила для порта 8080 и VLC, и телевизор получили список каналов и отображали их!

На данном этапе сервер копировался на роутер в [B]/tmp/[/B] и запускался вручную. Добавил скрипт, который загружает плейлист с [URL="http://ott.tv.planeta.tc/plst.m3u"]http://ott.tv.planeta.tc/plst.m3u[/URL] (хорошо, что он доступен по HTTP, а то [B]wget[/B] на роутере не поддерживает HTTPS) и делит его на несколько файлов по категориям. Также добавил сервис в [B]/etc/rc.d/[/B], который распаковывал и запускал бы сервер при загрузке роутера.

Затем нужно было записать изменения в память роутера. Изучая обсуждение подобных роутеров и прошивки для них (кстати, тоже [URL="http://wive-ng.sourceforge.net/index-old.php?WR-NL_RT3050%282%29"]русскоязычных авторов[/URL], [URL="https://wi-cat.ru/"]новый сайт[/URL]), встречал упоминание возможности записать файловую систему во flash. В роутере используется микросхема [URL="https://en.wikipedia.org/wiki/Memory_Technology_Device"]MTD[/URL] (низкоуровневая flash-память, без коррекции ошибок, выравнивания износа между ячейками и т. д.) размером 4 Мб. Файловая система занимала 2.6 Мб, а архив с сервером — всего 500-600 кб, он должен был поместиться. Долго не решался записать что-либо во flash, так как было не понятно, чем может обернуться эта процедура.

Когда всё же вызвал [B]fs save[/B], оказалось, что новые файлы не помещаются во flash! Причём размер, в который нужно уложиться был неизвестен. Начал искать, как уменьшить размер архива с сервером. При сборке и так была выбрана оптимизация по размеру, отладочная информация обрезалась, степень сжатия архива максимальная по умолчанию. Самой большой частью сервера была библиотека Lua (скрипты и плагины на этом языке можно подключать к серверу). Так как он справляется с плейлистом и без них, убрал её, а заодно и пару других, которые требовались для неё. Размер архива сократился до 150 кб, но он по-прежнему не помещался во flash.

Вскоре попробовал записать flash без новых крупных файлов, и оказалось, что максимальный размер записываемых данных всего 192 кб, из которых 64 кб уже заняты. То есть, нужно было уложиться в оставшиеся 128 кб. Пробовал убрать ещё некоторые самые крупные компоненты сервера, но без них он не работал. Тогда проверил, что сам исполняемый файл сжимается до 92 кб. Почти всё остальное место занимали… картинки из ресурсов веб-страниц! Неудивительно, что они не сжимались. Пересохранил три .png в .jpg с качеством 30%, скопировал архив на роутер в очередной раз, записал во flash, и он поместился почти впритык.

После перезагрузки роутера новые файлы (архив с сервером в [B]/etc/[/B], сервис в [B]/etc/rc.d/[/B], символьная ссылка на него в [B]/etc/init.d/[/B]) остались на своих местах. Плейлист загрузился, сервер запустился, VLC и телевизор получили список каналов, которые можно воспроизводить. Правда, при воспроизведении изображение время от времени виснет на секунду-другую. С чем связаны зависания, не известно, и, возможно, их можно исправить, подобрав настройки таймаутов и буферизации в конфигурации сервера. Во время воспроизведения процессор роутера занят на 5-10%.

Код xupnpd2 с изменениями для запуска на роутере находится в [URL="https://github.com/ayampolsky/xupnpd2"]репозитории[/URL].

Установить сервер на роутер можно по следующей инструкции.

1. Отключить на роутере встроенный DLNA-сервер, если он включен.
Перейти на страницу «Другие настройки».
Выбрать в Services -> Miscellaneous -> Astra DLNA (WMS version 0.7.1) значение Disable
Выбрать в Services -> Miscellaneous -> Astra DLNA Beta значение Disable
Перейти на страницу «Начало», проверить, что переключатель «Медиа-сервер» выключен.

2. Загрузить архив с кодом и архив с сервером [B]xupnpd2.tar.bz2[/B] [URL="https://github.com/ayampolsky/xupnpd2/releases/"]здесь[/URL]. Если нужно собрать исполняемый файл самостоятельно, перейти к п. 5.

3. При необходимости установить программы для копирования файлов через SFTP (в Windows удобно использовать [URL="https://winscp.net/"]WinSCP[/URL]) и подключения по SSH (в Windows удобно использовать [URL="https://www.putty.org/"]PuTTY[/URL]).

4 Скопировать [B]xupnpd2.tar.bz2[/B] на роутер в [B]/etc/[/B].
Скопировать [B]etc/rc.d/S91xupnpd2[/B] из архива с кодом на роутер в [B]/etc/rc.d/S91xupnpd2[/B].
Задать права для [B]/etc/rc.d/S91xupnpd2[/B].
[B]chmod 755 /etc/rc.d/S91xupnpd2[/B].
Перейти к п. 10.

5. Создать toolchain для MIPS, например, как рассказано выше.

6. Распаковать архив с кодом или загрузить [URL="https://github.com/ayampolsky/xupnpd2"]репозиторий[/URL].

7. В [B]Makefile.rt305x[/B] исправить путь к toolchain в [B]STAGING_DIR[/B].

8. Собрать xupnpd.
[B]make -f Makefile.rt305x clean
make -f Makefile.rt305x[/B]

Проверить, что собран статический исполняемый файл для MIPS.
[B]file xupnpd
xupnpd: ELF 32-bit LSB executable, MIPS, MIPS32 rel2 version 1 (SYSV), statically linked, stripped[/B]

9. Создать архив с сервером и скопировать файлы на роутер.
[B]./upload_to_router.sh <ROUTER_IP_ADDRESS>[/B]

10. На роутере создать символьную ссылку в [B]/etc/init.d/[/B].
[B]ln -s ../rc.d/S91xupnpd2 /etc/init.d/xupnpd2[/B]

11. Записать изменения файловой системы во flash.
[B]fs save[/B]

12. Перезагрузить роутер
[B]reboot[/B]
После перезагрузки через 30 секунд установится правило iptables, загрузится плейлист, запустится сервер.
Можно проверить, что архив и сервисы на месте.
[B]ls -la `find /etc/ | grep xupnpd`[/B]
Архив распакован в [B]/tmp/[/B].
[B]ls -la /tmp/xupnpd2/[/B]
Плейлист загружен и разделён на категории.
[B]ls -la /tmp/xupnpd2/media/[/B]
Сервер запущен.
[B]ps | grep xupnpd[/B]
Правило iptables задано.
[B]iptables -n -L | grep 8080[/B]
И, конечно, что телеканалы воспроизводятся.

Готов рассказать энтузиастам подробнее, как установить xupnpd2 на их собственный роутер SNR-CPE-W4N с прошивкой от Планеты. И посодействовать Планете в добавлении xupnpd2 в свою прошивку (особенно, если её автор согласится выпустить новую версию). Правда, xupnpd2, вроде бы, платный для использования организациями.

Если в телевизоре (или PlayStation 3, Xbox One и других устройствах, выпущенных хоть 10-15 лет назад) есть DLNA-клиент и декодер H.264, то для воспроизведения телевидения вовсе не нужна дополнительная коробочка с Android, превышающая по производительности офисный компьютер. Примерно о том же говорит автор xupnpd на своём сайте.
