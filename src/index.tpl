<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
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
            background-color: #fffefb; /* Creamy background */
            box-shadow: 0 2px 5px rgba(0,0,0,.1); /* Shadow effect */
            margin-bottom: 20px;
        }
        .vs-desc { font-size: larger; }
        .vs-name { background-color: #FFD;}
        .footer {
            position: fixed;
            left: 0;
            bottom: 0;
            width: 100%;
            background-color: #f0f0f5; /* Grayish footer */
            font-size: 0.8em;
            padding: 10px;
        }
       .footer > div {
            display: flex;
            justify-content: space-between;
        }

        @media (max-width: 768px) {
            .container.py-4 { padding-left: 10px; padding-right: 10px; }
            .vs-box { font-size: x-large; } /* Larger font size on mobile screens */
        }
    </style>
</head>
<body>
    <div class="container">
        <link href="https://fonts.googleapis.com/css2?family=Playfair+Display&display=swap" rel="stylesheet">
        <h1 class="text-center" style="font-family: 'Playfair Display', serif;">{{ site.head.title }}</h1>
    </div>
    <div class="container py-4">
        <div class="row row-cols-1 row-cols-lg-2 g-4">
            {% for service_name, service in site.container.links.items() %}
            <div class="col">
                <div class="{{ service.class }}">
                    <h3 class="vs-name">{{ service.name }}</h3>
                    <p class="text-muted vs-desc">{{ service.description }}</p>
                    <a href="http://{{ service.link }}" target="_blank" class="btn btn-primary float-end">
                        {{ service.linkname }} →
                    </a>
                </div>
            </div>
            {% endfor %}
        </div>
    </div>
    <div class="py-4">
        <div class="footer">
            <div class="left">{{ site.footer.left }}</div>
            <div class="middle">{{ site.footer.middle }}</div>
            <div class="right">{{ site.footer.right | safe }}</div>
        </div>
    </div>
</body>
</html>