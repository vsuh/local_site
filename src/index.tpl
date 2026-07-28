<!DOCTYPE html>
<html lang="ru" data-bs-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="apple-touch-icon" sizes="180x180" href="{{ site.parameters.icons }}/apple-touch-icon.png">
    <link rel="icon" type="image/png" sizes="32x32" href="{{ site.parameters.icons }}/favicon-32x32.png">
    <link rel="icon" type="image/png" sizes="16x16" href="{{ site.parameters.icons }}/favicon-16x16.png">
    <link rel="manifest" href="{{ site.parameters.icons }}/site.webmanifest">

    <title>{{ site.head.title }}</title>
    <link rel="stylesheet" href="{{ site.parameters.css }}/styles.css">
</head>
<body>

    <header class="vs-hero">
        <p class="vs-prompt">root@vscraft:~$ ./launch_dashboard</p>
        <h1>VSCraft<span class="vs-cursor">_</span>workshop</h1>
        <p class="vs-sub">{{ site.container.links|length }} сервисов &middot; локальная сеть</p>
    </header>

    <main class="vs-grid">
        {% for service_name, service in site.container.links.items() %}
        <div class="vs-card">
            <div class="vs-row">
                <span class="vs-name">{{ service.name }}</span>
                <span class="vs-tag">{{ service.tag }}</span>
            </div>
            <p class="vs-desc">{{ service.description }}</p>
            <div class="vs-actions">
                <a href="#" data-port="{{ service.port }}" data-link="{{ service.link }}" target="_blank" class="vs-btn service-link">
                    {{ service.linkname }} &rarr;
                </a>
                <a href="{{ service.infolink }}" class="vs-info" target="_blank" title="Подробнее">&#9432;</a>
            </div>
        </div>
        {% endfor %}
    </main>

    <footer class="vs-footer">
        <span>{{ site.footer.left | safe }}</span>
        <span>{{ site.footer.right | safe }}</span>
    </footer>

    <script src="{{ site.parameters.scripts }}/vscraft.js"></script>
</body>
</html>
