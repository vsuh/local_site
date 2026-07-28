document.addEventListener("DOMContentLoaded", () => {
    const host = location.hostname;
    const currentPort = location.port || (location.protocol === 'https:' ? '443' : '80');
    const currentFull = `${host}:${currentPort}`;
    const base = `${location.protocol}//${host}`;

    document.querySelectorAll(".service-link").forEach(link => {
        const { port, link: serviceLink } = link.dataset;

        if (serviceLink) {
            link.href = serviceLink;
        } else if (port) {
            link.href = `${base}:${port}`;
            if (port === currentPort || `${host}:${port}` === currentFull) {
                link.classList.add('current');
            }
        }
    });
});