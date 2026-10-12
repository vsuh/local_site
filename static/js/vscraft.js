document.addEventListener("DOMContentLoaded", () => {
    const host = location.hostname;
    const base = `${location.protocol}//${host}`;
    const body = document.body;
    const healthUrl = body.dataset.healthUrl || "/static/health.json";
    const configuredInterval = Number(body.dataset.healthInterval);
    const refreshInterval = Number.isFinite(configuredInterval) && configuredInterval > 0
        ? configuredInterval * 1000
        : 30000;

    const serviceLinks = [...document.querySelectorAll(".service-link, .vs-nav-item[data-port], .vs-nav-item[data-link]")];
    serviceLinks.forEach(link => {
        const port = (link.dataset.port || "").trim();
        const serviceLink = (link.dataset.link || "").trim();
        if (serviceLink) link.href = serviceLink;
        else if (port) link.href = `${base}:${port}`;
        if (link.matches(".service-link")) link.rel = "noopener noreferrer";
    });

    const cards = [...document.querySelectorAll(".vs-service")];
    const statusLine = document.querySelector(".vs-sidebar-status .vs-status-line:not(.dim)");
    const headerPing = document.querySelector(".vs-header-ping");
    let latestStatuses = new Map();
    let healthAvailable = false;

    cards.forEach(card => {
        const link = card.querySelector(".service-link");
        const port = (link?.dataset.port || "").trim();
        const badge = document.createElement("span");
        badge.className = "vs-service-status " + (port ? "is-checking" : "is-external");
        badge.textContent = port ? "Checking" : "External";
        badge.setAttribute("aria-live", "polite");
        const header = card.querySelector(".vs-service-header");
        if (header) header.appendChild(badge);
        card.dataset.health = port ? "checking" : "external";
    });

    function setCardStatus(card, status, details = "") {
        const badge = card.querySelector(".vs-service-status");
        if (!badge) return;
        const labels = {
            online: "Online",
            offline: "Offline",
            checking: "Checking",
            unknown: "Unknown",
            external: "External"
        };
        const safeStatus = Object.hasOwn(labels, status) ? status : "unknown";
        badge.className = `vs-service-status is-${safeStatus}`;
        badge.textContent = labels[safeStatus];
        badge.title = details;
        card.dataset.health = safeStatus;
    }

    function updateSummary() {
        const monitored = cards.filter(card => (card.querySelector(".service-link")?.dataset.port || "").trim());
        const online = monitored.filter(card => card.dataset.health === "online").length;
        const offline = monitored.filter(card => card.dataset.health === "offline").length;
        const checking = monitored.filter(card => card.dataset.health === "checking").length;
        const unknown = monitored.filter(card => card.dataset.health === "unknown").length;

        if (statusLine) {
            statusLine.dataset.health = "true";
            statusLine.classList.toggle("has-offline", offline > 0 || unknown > 0);
            statusLine.textContent = !healthAvailable
                ? "● HEALTH DATA UNAVAILABLE"
                : checking
                    ? `● CHECKING · ${online} online · ${offline} offline`
                    : unknown
                        ? `● PARTIAL DATA · ${online} online · ${offline} offline`
                        : offline
                            ? `● ATTENTION · ${online} online · ${offline} offline`
                            : `● ONLINE · ${online}/${monitored.length} services`;
        }
        if (headerPing) {
            const label = !healthAvailable ? "Health data unavailable"
                : checking ? "Updating service status…"
                : offline ? "Service attention required"
                : unknown ? "Some statuses unknown"
                : "All systems responding";
            const textNode = [...headerPing.childNodes].find(node => node.nodeType === Node.TEXT_NODE);
            if (textNode) textNode.textContent = label;
            else headerPing.append(document.createTextNode(label));
            const dot = headerPing.querySelector(".vs-ping-dot");
            if (dot) dot.style.background = !healthAvailable || unknown ? "var(--amber)" : offline ? "var(--red)" : checking ? "var(--amber)" : "var(--green)";
        }
    }

    async function refreshHealth() {
        cards.forEach(card => {
            const port = (card.querySelector(".service-link")?.dataset.port || "").trim();
            if (port) setCardStatus(card, "checking", "Waiting for the server health-check data.");
        });
        updateSummary();
        try {
            const separator = healthUrl.includes("?") ? "&" : "?";
            const response = await fetch(`${healthUrl}${separator}_=${Date.now()}`, {
                cache: "no-store",
                headers: { "Accept": "application/json" }
            });
            if (!response.ok) throw new Error(`Health endpoint returned HTTP ${response.status}`);
            const data = await response.json();
            if (!data || typeof data.services !== "object") throw new Error("Invalid health-check payload");
            healthAvailable = true;
            latestStatuses = new Map(Object.entries(data.services));

            cards.forEach(card => {
                const link = card.querySelector(".service-link");
                const port = (link?.dataset.port || "").trim();
                if (!port) {
                    setCardStatus(card, "external", "External link; no local port to check.");
                    return;
                }
                const service = [...latestStatuses.values()].find(item => String(item.port) === port);
                if (!service) {
                    setCardStatus(card, "unknown", "No status was found for this port in the server health data.");
                    return;
                }
                const status = service.status;
                const checked = service.checked_at ? `Last checked: ${service.checked_at}` : "";
                const reason = service.error ? ` Details: ${service.error}` : "";
                setCardStatus(card, status, [checked, reason.trim()].filter(Boolean).join(" · "));
            });
        } catch (error) {
            healthAvailable = false;
            cards.forEach(card => {
                const port = (card.querySelector(".service-link")?.dataset.port || "").trim();
                if (port) setCardStatus(card, "unknown", `Could not read server health data: ${error.message}`);
            });
        }
        updateSummary();
    }

    refreshHealth();
    window.setInterval(refreshHealth, refreshInterval);
});
