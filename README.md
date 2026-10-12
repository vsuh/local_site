# local_site

Корневая страница локальной сети с каталогом сервисов. Описание берётся из `src/site.json`, HTML строится шаблоном `src/index.tpl` через `src/generate.py`.

## Состав проекта

- `src/site.json` — заголовок, ссылки, порты сервисов и настройки проверки здоровья.
- `src/index.tpl` — HTML-шаблон главной страницы.
- `src/generate.py` — генерация корневого `index.html`.
- `static/css/styles.css` и `static/js/vscraft.js` — оформление и интерфейс.
- `src/healthcheck.py` — серверная проверка TCP-портов с публикацией результатов в JSON.

## Настройки

В `src/site.json`, внутри объекта `site`, находится раздел:

```json
"healthcheck": {
    "interval_seconds": 30,
    "timeout_seconds": 3
}
```

- `interval_seconds` — интервал проверки по умолчанию в секундах; страница обновляет данные с учётом этого значения.
- `timeout_seconds` — таймаут TCP-подключения по умолчанию в секундах.
- В записи конкретного сервиса внутри `site.container.links` можно задать `interval_seconds` и/или `timeout_seconds`. Эти параметры переопределяют глобальные значения только для этого сервиса.
- Браузер обновляет статусы только когда вкладка видима и имеет фокус. При потере фокуса таймер останавливается, а выполняющийся запрос отменяется; при возвращении фокуса проверка возобновляется.

Для локальных сервисов проверяется TCP-подключение к `127.0.0.1:<port>`. Это подтверждает доступность порта, но не проверяет корректность HTTP-ответа или работоспособность приложения на уровне бизнес-логики. Для сервиса, слушающего на другом адресе, можно указать в его записи `"health_host": "адрес"`. Сервисы без `port`, у которых задана внешняя ссылка, обозначаются как `External`.

## Запуск серверной проверки

Проверяющий процесс нужно запускать на том же сервере, где работают сервисы, и направить файл результатов в каталог `static`, который реально отдаёт веб-сервер. Например, если репозиторий находится в `/opt/local_site`, а корень сайта — `/var/www/html`:

```bash
python3 /opt/local_site/src/healthcheck.py \
  --config /opt/local_site/src/site.json \
  --output /var/www/html/static/health.json
```

Команда работает непрерывно и обновляет JSON с периодом из `site.json`. Для быстрой проверки один раз можно выполнить:

```bash
python3 src/healthcheck.py --once
```

При запуске с параметрами по умолчанию файл создаётся в `static/health.json` репозитория. Убедитесь, что у пользователя процесса есть право записи в каталог результатов, а веб-сервер может читать файл. Не открывайте отдельный порт наружу: браузер получает JSON с того же origin, что и главная страница.

### Пример systemd-службы

Создайте `/etc/systemd/system/local-site-healthcheck.service`, заменив пути на свои:

```ini
[Unit]
Description=Local site service health checks
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/local_site/src/healthcheck.py --config /opt/local_site/src/site.json --output /var/www/html/static/health.json
Restart=always
RestartSec=5
User=www-data

[Install]
WantedBy=multi-user.target
```

Затем активируйте службу:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now local-site-healthcheck.service
sudo systemctl status local-site-healthcheck.service
```

Если `www-data` не имеет доступа к портам или каталогу публикации, выберите подходящего пользователя и настройте права на запись в `static/health.json`.

## Генерация HTML

Для генерации `index.html` локально:

```bash
python3 -m pip install -r requirements.txt
python3 src/generate.py
```

Чтобы автоматически генерировать страницу при коммите, установите git hook:

```bash
git config --local core.hooksPath .githooks
chmod +x .githooks/pre-commit
```

Hook запускает генератор и добавляет полученный `index.html` в коммит. Если изменения отправляются через GitHub API, hook автоматически не запускается — тогда обновлённый `index.html` должен быть включён в коммит отдельно.


## Автоматическая сборка и публикация

Workflow `.github/workflows/deploy.yml` запускается при push в `master` или вручную через GitHub Actions. Он проверяет JSON, генерирует `index.html`, коммитит его в `master`, если файл изменился, затем подключается к серверу и отправляет актуальный `master` в bare-репозиторий `/opt/www-bare.git`. Его `post-receive` публикует файлы в `/var/www/html`.

В настройках репозитория GitHub откройте **Settings → Secrets and variables → Actions** и создайте secrets:

- `DEPLOY_HOST` — публичное DNS-имя или IP сервера, доступный с GitHub Actions.
- `DEPLOY_USER` — SSH-пользователь, у которого есть доступ к `/opt/www-repo` и право выполнять `git push live master`.
- `DEPLOY_SSH_KEY` — приватный SSH-ключ для подключения к серверу; соответствующий публичный ключ должен быть в `~/.ssh/authorized_keys` пользователя.
- `DEPLOY_KNOWN_HOSTS` — проверенная запись host key сервера для `known_hosts`, полученная и сверенная безопасным способом.
- `DEPLOY_PORT` — необязательный SSH-порт; если не задан, используется `22`.

На сервере пользователь деплоя должен иметь возможность выполнить в `/opt/www-repo` команды `git fetch origin master`, `git pull --ff-only origin master` и `git push live master` без интерактивного ввода. Remote `origin` должен вести на этот GitHub-репозиторий, а remote `live` — на `/opt/www-bare.git`.

Перед первым запуском убедитесь, что изменения в `/var/www/html`, отсутствующие в репозитории, сохранены отдельно: публикация обновляет отслеживаемые Git-файлы. Не добавляйте приватный ключ в репозиторий и не отключайте проверку SSH host key.
