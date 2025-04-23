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
        .vs-title {}
        .vs-box {
            font-family: helvetica;
            border: 1px solid #bbc;
            border-radius: 10px;
            padding: 20px;
            background-color:#ffd; 
            margin-bottom: 20px;
        }
        .vs-box .vs-desc {
            font-size: smaller;
}
        .footer {
            position: fixed;
            left: 0;
            bottom: 0;
            width: 100%;
            background-color: #f0f0f5; /* Slightly different background */
            font-size: 0.8em;
            padding: 10px;
        }
        .footer > div {
            display: flex;
            justify-content: space-between;
        }

    </style>
</head>
<body>
    <div class="container">
        <link href="https://fonts.googleapis.com/css2?family=Playfair+Display&display=swap" rel="stylesheet">
        <h1 class="text-start" style="font-family: 'Playfair Display', serif; font-size: 2em; margin-top: 10px;">{{ site.head.title }}</h1>
    </div>
    <div class="container py-4">
       <div class="row row-cols-1 row-cols-md-2 g-4">
            {% for service_name, service in site.container.links.items() %}
            <div class="col">
                <div class="{{ service.class }}">
                    <h3>{{ service.name }}</h3>
                    <p class="text-muted vs-desc">{{ service.description }}</p>
                     <a href="http://{{ service.link }}" target="_blank" class="btn btn-primary float-end">
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
</body>
</html>