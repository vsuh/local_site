document.addEventListener("DOMContentLoaded", () => {
    const host = location.hostname;
    const base = `${location.protocol}//${host}`;
    const serviceLinks = [...document.querySelectorAll(".service-link, .vs-nav-item[data-port], .vs-nav-item[data-link]")];

    serviceLinks.forEach(link => {
        const port = (link.dataset.port || "").trim();
        const serviceLink = (link.dataset.link || "").trim();
        if (serviceLink) {
            link.href = serviceLink;
        } else if (port) {
            link.href = `${base}:${port}`;
        }
        if (link.matches(".service-link")) link.rel = "noopener noreferrer";
    });

    const cards = [...document.querySelectorAll(".vs-service")];
    const statusLine = document.querySelector(".vs-sidebar-status .vs-status-line:not(.dim)");
    const headerPing = document.querySelector(".vs-header-ping");
    const results = new Map();

    cards.forEach(card => {
        const link = card.querySelector(".service-link");
        const port = (link?.dataset.port || "").trim();
        const external = (link?.dataset.link || "").trim();
        const badge = document.createElement("span");
        badge.className = "vs-service-status " + (port ? "is-checking" : "is-external");
        badge.textContent = port ? "Checking" : "External";
        badge.setAttribute("aria-live", "polite");
        const header = card.querySelector(".vs-service-header");
        if (header) header.appendChild(badge);
        card.dataset.health = port ? "checking" : "external";
        if (!port) return;
        const url = `${base}:${port}`;
        results.set(port, "checking");
        badge.dataset.port = port;
        badge.dataset.health = "checking";
        badge.title = `Checking ${url}`;
    });

    const timeoutFetch = (url, timeoutMs = 3000) => {
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), timeoutMs);
        return fetch(url, { mode: "no-cors", cache: "no-store", signal: controller.signal })
            .finally(() => clearTimeout(timer));
    };

    async function checkCard(card) {
        const link = card.querySelector(".service-link");
        const port = (link?.dataset.port || "").trim();
        if (!port) return;
        const url = `${base}:${port}`;
        const badge = card.querySelector(".vs-service-status");
        card.dataset.health = "checking";
        if (badge) {
            badge.className = "vs-service-status is-checking";
            badge.textContent = "Checking";
        }
        try {
            await timeoutFetch(url);
            card.dataset.health = "online";
            results.set(port, "online");
            if (badge) {
                badge.className = "vs-service-status is-online";
                badge.textContent = "Online";
                badge.title = "Connection responded; browser cannot inspect HTTP status in no-cors mode.";
            }
        } catch (_) {
            card.dataset.health = "offline";
            results.set(port, "offline");
            if (badge) {
                badge.className = "vs-service-status is-offline";
                badge.textContent = "Offline";
                badge.title = "No browser-visible response within 3 seconds. CORS or mixed-content restrictions may affect this result.";
            }
        }
        updateSummary();
    }

    function updateSummary() {
        const monitored = [...results.values()];
        const online = monitored.filter(value => value === "online").length;
        const offline = monitored.filter(value => value === "offline").length;
        const checking = monitored.filter(value => value === "checking").length;
        if (statusLine) {
            statusLine.dataset.health = "true";
            statusLine.classList.toggle("has-offline", offline > 0);
            statusLine.textContent = checking
                ? `● CHECKING · ${online} online · ${offline} offline`
                : offline
                    ? `● ATTENTION · ${online} online · ${offline} offline`
                    : `● ONLINE · ${online}/${monitored.length} services`;
        }
        if (headerPing) {
            const label = offline ? "Service attention required" : checking ? "Checking services…" : "All systems responding";
            headerPing.lastChild.textContent = label;
            const dot = headerPing.querySelector(".vs-ping-dot");
            if (dot) dot.style.background = offline ? "var(--red)" : checking ? "var(--amber)" : "var(--green)";
        }
    }

    updateSummary();
    const runChecks = () => cards.forEach(card => checkCard(card));
    runChecks();
    window.setInterval(runChecks, 30000);
});
