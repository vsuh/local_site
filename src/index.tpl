<!DOCTYPE html>
<html lang="ru">
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

    <!-- Sidebar -->
    <aside class="vs-sidebar">
        <div class="vs-logo">
            <span class="vs-logo-main">VSCraft</span>
            <span class="vs-logo-sub">Workshop</span>
        </div>

        <nav>
            <div class="vs-nav-label">Services</div>
            <ul class="vs-nav">
                {% for key, svc in site.container.links.items() %}
                <li>
                    <a href="#" data-port="{{ svc.port }}" data-link="{{ svc.link }}"
                       class="vs-nav-item tag-{{ svc.tag }}" target="_blank">
                        <span class="vs-dot tag-{{ svc.tag }}"></span>
                        {{ svc.name }}
                    </a>
                </li>
                {% endfor %}
            </ul>
        </nav>

        <div class="vs-sidebar-status">
            <div class="vs-status-line">● ONLINE · {{ site.container.links | length }}/{{ site.container.links | length }}</div>
            <div class="vs-status-line dim">{{ site.head.host }} · local</div>
        </div>
    </aside>

    <!-- Header -->
    <header class="vs-header">
        <span class="vs-header-title">{{ site.head.title }}</span>
        <div class="vs-header-ping">
            <span class="vs-ping-dot"></span>
            All systems are go
        </div>
    </header>

    <!-- Main -->
    <main class="vs-main">

        <!-- Column 1: infra + net + sync -->
        <div class="vs-col">
            <div class="vs-col-label tag-infra">
                <span class="vs-dot tag-infra"></span>infra · net · sync
            </div>
            {% for key, svc in site.container.links.items() if svc.tag in ['infra', 'net', 'sync'] %}
            <div class="vs-service">
                <div class="vs-service-header">
                    <span class="vs-service-name">{{ svc.name }}</span>
                    <span class="vs-service-port">{% if svc.port %}:{{ svc.port }}{% else %}↗ ext{% endif %}</span>
                </div>
                <div class="vs-service-desc">{{ svc.description }}</div>
                <a href="#" data-port="{{ svc.port }}" data-link="{{ svc.link }}"
                   class="service-link tag-{{ svc.tag }}" target="_blank">→ {{ svc.linkname }}</a>
            </div>
            {% endfor %}
        </div>

        <!-- Column 2: media -->
        <div class="vs-col">
            <div class="vs-col-label tag-media">
                <span class="vs-dot tag-media"></span>media
            </div>
            {% for key, svc in site.container.links.items() if svc.tag == 'media' %}
            <div class="vs-service">
                <div class="vs-service-header">
                    <span class="vs-service-name">{{ svc.name }}</span>
                    <span class="vs-service-port">{% if svc.port %}:{{ svc.port }}{% else %}↗ ext{% endif %}</span>
                </div>
                <div class="vs-service-desc">{{ svc.description }}</div>
                <a href="#" data-port="{{ svc.port }}" data-link="{{ svc.link }}"
                   class="service-link tag-{{ svc.tag }}" target="_blank">→ {{ svc.linkname }}</a>
            </div>
            {% endfor %}
        </div>

        <!-- Column 3: docs + bot -->
        <div class="vs-col">
            <div class="vs-col-label tag-tools">
                <span class="vs-dot tag-net"></span>tools · docs
            </div>
            {% for key, svc in site.container.links.items() if svc.tag in ['docs', 'bot'] %}
            <div class="vs-service">
                <div class="vs-service-header">
                    <span class="vs-service-name">{{ svc.name }}</span>
                    <span class="vs-service-port">{% if svc.port %}:{{ svc.port }}{% else %}↗ ext{% endif %}</span>
                </div>
                <div class="vs-service-desc">{{ svc.description }}</div>
                <a href="#" data-port="{{ svc.port }}" data-link="{{ svc.link }}"
                   class="service-link tag-{{ svc.tag }}" target="_blank">→ {{ svc.linkname }}</a>
            </div>
            {% endfor %}
        </div>

    </main>

    <!-- Footer -->
    <footer class="vs-footer">
        <span class="vs-footer-left">{{ site.footer.left }}</span>
        <div class="vs-footer-right">{{ site.footer.right | safe }}</div>
    </footer>

    <script src="{{ site.parameters.scripts }}/vscraft.js"></script>
</body>
</html>
