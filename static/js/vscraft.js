document.addEventListener("DOMContentLoaded", () => {
    const host = location.hostname;
    const base = `${location.protocol}//${host}`;

    document.querySelectorAll(".service-link, .vs-nav-item[data-port], .vs-nav-item[data-link]").forEach(link => {
        const port = link.dataset.port;
        const serviceLink = link.dataset.link;

        if (serviceLink) {
            link.href = serviceLink;
        } else if (port) {
            link.href = `${base}:${port}`;
        }
    });
});