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
        body { font-size: 1.1rem; line-height: 1.5; }
        h1 { font-size: 2.5em; margin-top: 10px; text-align: center; }
        .vs-box {
            font-family: Helvetica, sans-serif;
            border: 1px solid #bbb;
            border-radius: 10px;
            padding: 20px;
            background-color: #fffefb; /* Кремовый оттенок фона */
            box-shadow: 0 2px 5px rgba(0,0,0,.1); /* Тень */
            margin-bottom: 20px;
        }
        .vs-desc { font-size: larger; color: #666; }
        .footer {
            position: fixed;
            left: 0;
            bottom: 0;
            width: 100%;
            background-color: #f0f0f5; /* Серый фон подвала */
            font-size: 0.8em;
            padding: 10px;
        }
        @media (min-width: 768px) {
            .row-cols-custom { grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); }
        }
        @media (max-width: 768px) {
            .container.py-4 { padding-left: 10px; padding-right: 10px; }
            .vs-box { font-size: large; }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="text-center" style="font-family: 'Playfair Display', serif;">{{ site.head.title }}</h1>
    </div>
    <div class="container py-4">
        <div class="row row-cols-1 row-cols-lg-2 g-4 row-cols-custom">
            {% for service_name, service in site.container.links.items() %}
            <div class="col">
                <div class="{{ service.class }}">
                    <h3>{{ service.name }}</h3>
                    <p class="text-muted vs-desc">{{ service.description }}</p>
                    <a href="http://{{ service.link }}" target="_blank" class="btn btn-primary d-block w-100 mt-2">
                        {{ service.linkname }} →
                    </a>
                </div>
            </div>
            {% endfor %}
        </div>
    </div>
    <div class="footer">
        <div>
            <div class="left">{{ site.footer.left }}</div>
            <div class="middle">{{ site.footer.middle }}</div>
            <div class="right">{{ site.footer.right | safe }}</div>
        </div>
    </div>
</body>
</html>