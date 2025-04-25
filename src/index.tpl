<!DOCTYPE html>
<html lang="ru" data-bs-theme="auto">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="apple-touch-icon" sizes="180x180" href="{{ site.parameters.icons }}/apple-touch-icon.png">
    <link rel="icon" type="image/png" sizes="32x32" href="{{ site.parameters.icons }}/favicon-32x32.png">
    <link rel="icon" type="image/png" sizes="16x16" href="{{ site.parameters.icons }}/favicon-16x16.png">
    <link rel="manifest" href="{{ site.parameters.icons }}/site.webmanifest">

    <title>{{ site.head.title }}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.5/font/bootstrap-icons.css" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ site.parameters.css}}/styles.css">
</head>
<body>

    <div class="container d-flex align-items-center justify-content-between">
        <h1 class="text-center flex-fill">{{ site.head.title }}</h1>
        <div class="form-check form-switch ms-auto">
            <input class="form-check-input" title="dark/light theme" type="checkbox" id="themeSwitcher" role="switch">
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

    <script src="{{ site.parameters.scripts }}/vscraft.js"></script>
</body>
</html>