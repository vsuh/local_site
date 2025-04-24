<!DOCTYPE html>
<html lang="ru" data-bs-theme="auto">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="apple-touch-icon" sizes="180x180" href="/static/icons/apple-touch-icon.png">
    <link rel="icon" type="image/png" sizes="32x32" href="/static/icons/favicon-32x32.png">
    <link rel="icon" type="image/png" sizes="16x16" href="/static/icons/favicon-16x16.png">
    <link rel="manifest" href="/static/icons/site.webmanifest">

    <title>{{ site.head.title }}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ site.parameters.css}}/styles.css"> <!-- Подключение внешних стилей -->
</head>
<body>

    <div class="container d-flex align-items-center justify-content-between">
        <h1 class="text-center flex-fill">{{ site.head.title }}</h1>
        <div class="form-check form-switch ms-auto">
            <input class="form-check-input" title="Theme switcher" type="checkbox" id="themeSwitcher" role="switch">
            <label class="form-check-label visually-hidden" for="themeSwitcher">Темная тема</label>
        </div>
    </div>

    <div class="container py-4">
        <div class="row row-cols-1 row-cols-md-2 g-4">
            {% for service_name, service in site.container.links.items() %}
            <div class="col">
                <div class="card shadow-sm border-1 h-100">
                    <div class="card-header">
                        <h3 class="m-0">{{ service.name }}</h3>
                    </div>
                    <div class="card-body">
                        <p class="vs-desc text-muted">{{ service.description }}</p>
                        <a href="#" data-port="{{ service.port }}" target="_blank" class="btn btn-primary service-link">
                            <i class="bi bi-arrow-return-right"></i> {{ service.linkname }}
                        </a>
                    </div>
                </div>
            </div>
            {% endfor %}
        </div>
    </div>

    <footer class="footer w-100 mt-5">
        <div class="container-fluid">
            <div class="d-flex justify-content-between">
                <div>{{ site.footer.left }}</div>
                <div>{{ site.footer.middle }}</div>
                <div>{{ site.footer.right | safe }}</div>
            </div>
        </div>
    </footer>

    <script>
        document.addEventListener("DOMContentLoaded", () => {
            const host = location.hostname;
            const currentPort = location.port || (location.protocol === 'https:' ? '443' : '80');
            const currentFull = `${host}:${currentPort}`;
            const base = `${location.protocol}//${host}`;

            document.querySelectorAll(".service-link").forEach(link => {
                const port = link.dataset.port;
                if (port) {
                    const fullUrl = `${base}:${port}`;
                    link.href = fullUrl;

                    if (`${host}:${port}` === currentFull) {
                        link.classList.add("current");
                        const label = document.createElement("span");
                        label.classList.add("ms-2", "fw-bold");
                        label.textContent = " (текущий адрес)";
                        link.appendChild(label);
                    }
                }
            });
        });
    </script>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            var themeSwitcher = document.getElementById('themeSwitcher');
            
            function setInitialTheme() {
                var storedTheme = localStorage.getItem('theme');
                if(storedTheme === 'dark') {
                    document.documentElement.setAttribute('data-bs-theme', 'dark');
                    themeSwitcher.checked = true;
                } else {
                    document.documentElement.removeAttribute('data-bs-theme');
                    themeSwitcher.checked = false;
                }
            }

            function saveThemePreference(theme) {
                localStorage.setItem('theme', theme);
            }

            themeSwitcher.addEventListener('change', function(event) {
                if(this.checked) {
                    document.documentElement.setAttribute('data-bs-theme', 'dark');
                    saveThemePreference('dark');
                } else {
                    document.documentElement.removeAttribute('data-bs-theme');
                    saveThemePreference('');
                }
            });

            setInitialTheme('dark'); // Загружаем начальную тему
        });
    </script>

</body>
</html>