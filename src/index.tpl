<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <link rel="apple-touch-icon" sizes="180x180" href="/static/icons/apple-touch-icon.png">
    <link rel="icon" type="image/png" sizes="32x32" href="/static/icons/favicon-32x32.png">
    <link rel="icon" type="image/png" sizes="16x16" href="/static/icons/favicon-16x16.png">
    <link rel="manifest" href="/static/icons/site.webmanifest">

    <title>{{ site.head.title }}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        .vs-box { font-family: helvetica; }
    </style>
</head>
<body>
    <div class="container py-4">
        <div class="row row-cols-1 row-cols-md-2 g-4">
            {% for service in site.container.links %}
            <div class="col">
                <div class="{{ service.class }}">
                    <h3>{{ service.name }}</h3>
                    <p class="text-muted">{{ service.description }}</p>
                    <a href="http://{{ service.link }}" target="_blank" class="btn btn-primary">
                        Открыть →
                    </a>
                </div>
            </div>
            {% endfor %}
        </div>
    </div>
</body>
</html>