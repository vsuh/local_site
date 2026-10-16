document.addEventListener("DOMContentLoaded", () => {
    const host = location.hostname;
    const base = `${location.protocol}//${host}`;
    const body = document.body;
    const healthUrl = body.dataset.healthUrl || "/static/health.json";
    const configuredInterval = Number(body.dataset.healthInterval);
    const defaultIntervalMs = Number.isFinite(configuredInterval) && configuredInterval > 0
        ? configuredInterval * 1000
        : 30000;

    function isAbsoluteHttpUrl(value) {
        try {
            const url = new URL(value);
            return (url.protocol === "http:" || url.protocol === "https:")
                && Boolean(url.hostname) && !url.username && !url.password;
        } catch {
            return false;
        }
    }

    function isMonitoredLink(link) {
        const port = (link?.dataset.port || "").trim();
        const url = (link?.dataset.link || "").trim();
        return Boolean(port || isAbsoluteHttpUrl(url));
    }
    // This is the deadline for fetching the JSON document, independent of TCP
    // connection timeouts used by the server-side health checker.
    const healthFetchTimeoutMs = 10000;

    const serviceLinks = [...document.querySelectorAll(".service-link, .vs-nav-item[data-port], .vs-nav-item[data-link]")];
    serviceLinks.forEach(link => {
        const port = (link.dataset.port || "").trim();
        const serviceLink = (link.dataset.link || "").trim();
        if (serviceLink) link.href = serviceLink;
        else if (port) link.href = `${base}:${port}`;
        if (link.matches(".service-link")) link.rel = "noopener noreferrer";
    });

    const cards = [...document.querySelectorAll(".vs-service")];
    const serviceIntervals = cards
        .map(card => Number(card.querySelector(".service-link")?.dataset.healthInterval))
        .filter(seconds => Number.isFinite(seconds) && seconds > 0)
        .map(seconds => seconds * 1000);
    const refreshInterval = serviceIntervals.length
        ? Math.min(defaultIntervalMs, ...serviceIntervals)
        : defaultIntervalMs;
    const maxServiceIntervalMs = serviceIntervals.length
        ? Math.max(defaultIntervalMs, ...serviceIntervals)
        : defaultIntervalMs;
    let refreshTimer = null;
    let activeRequest = null;
    let requestTimeout = null;
    let refreshInProgress = false;
    let refreshAbortedForPause = false;
    let refreshAgainImmediately = false;
    let requestTimedOut = false;

    function isPageActive() {
        return document.visibilityState === "visible" && document.hasFocus();
    }

    function scheduleRefresh() {
        if (!isPageActive() || refreshTimer !== null) return;
        refreshTimer = window.setTimeout(() => {
            refreshTimer = null;
            refreshHealth();
        }, refreshInterval);
    }

    function pauseRefresh() {
        if (refreshTimer !== null) {
            window.clearTimeout(refreshTimer);
            refreshTimer = null;
        }
        if (activeRequest) {
            refreshAbortedForPause = true;
            activeRequest.abort();
        }
    }

    function syncRefreshState() {
        if (isPageActive()) {
            if (refreshTimer === null && !refreshInProgress) refreshHealth();
        } else {
            pauseRefresh();
        }
    }
    const statusLine = document.querySelector(".vs-sidebar-status .vs-status-line:not(.dim)");
    const headerPing = document.querySelector(".vs-header-ping");
    let latestStatuses = new Map();
    let healthAvailable = false;

    cards.forEach(card => {
        const link = card.querySelector(".service-link");
        const port = (link?.dataset.port || "").trim();
        const url = (link?.dataset.link || "").trim();
        const monitored = Boolean(port || isAbsoluteHttpUrl(url));
        const badge = document.createElement("span");
        badge.className = "vs-service-status " + (monitored ? "is-checking" : "is-external");
        badge.textContent = monitored ? "Checking" : "External";
        badge.setAttribute("aria-live", "polite");
        const header = card.querySelector(".vs-service-header");
        if (header) header.appendChild(badge);
        card.dataset.health = monitored ? "checking" : "external";
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
        const monitored = cards.filter(card => {
            const link = card.querySelector(".service-link");
            return isMonitoredLink(link);
        });
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
        if (!isPageActive() || refreshInProgress) return;
        refreshInProgress = true;
        refreshAbortedForPause = false;
        refreshAgainImmediately = false;
        requestTimedOut = false;
        activeRequest = new AbortController();
        requestTimeout = window.setTimeout(() => {
            requestTimedOut = true;
            activeRequest?.abort();
        }, healthFetchTimeoutMs);
        cards.forEach(card => {
            const link = card.querySelector(".service-link");
            const monitored = isMonitoredLink(link);
            if (monitored) setCardStatus(card, "checking", "Waiting for the server health-check data.");
        });
        updateSummary();
        try {
            const separator = healthUrl.includes("?") ? "&" : "?";
            const response = await fetch(`${healthUrl}${separator}_=${Date.now()}`, {
                cache: "no-store",
                headers: { "Accept": "application/json" },
                signal: activeRequest.signal
            });
            if (!response.ok) throw new Error(`Health endpoint returned HTTP ${response.status}`);
            const data = await response.json();
            if (!data || typeof data.services !== "object") throw new Error("Invalid health-check payload");
            const updatedAt = Date.parse(data.updated_at || "");
            const staleAfterMs = Math.max(refreshInterval * 2, maxServiceIntervalMs * 2, 120000);
            if (!Number.isFinite(updatedAt) || Date.now() - updatedAt > staleAfterMs) {
                throw new Error("Server health data is stale; check that the health-check process is running.");
            }
            healthAvailable = true;
            latestStatuses = new Map(Object.entries(data.services));

            cards.forEach(card => {
                const link = card.querySelector(".service-link");
                const port = (link?.dataset.port || "").trim();
                const url = (link?.dataset.link || "").trim();
                if (!port && !isAbsoluteHttpUrl(url)) {
                    setCardStatus(card, "external", "No supported HTTP(S) URL or local port configured.");
                    return;
                }
                const serviceId = link?.dataset.healthId;
                const service = latestStatuses.get(serviceId)
                    || (port ? [...latestStatuses.values()].find(item => String(item.port) === port) : null);
                if (!service) {
                    setCardStatus(card, "unknown", "No status was found in the server health data.");
                    return;
                }
                const status = service.status;
                const checked = service.checked_at ? `Last checked: ${service.checked_at}` : "";
                const response = service.status_code ? `HTTP ${service.status_code}` : "";
                const reason = service.error ? ` Details: ${service.error}` : "";
                setCardStatus(card, status, [checked, response, reason.trim()].filter(Boolean).join(" · "));
            });
        } catch (error) {
            if (error.name === "AbortError" && !requestTimedOut) {
                // A request cancelled because the page lost focus is not a health
                // endpoint failure. If focus returned before rejection was handled,
                // retry immediately instead of waiting for the regular interval.
                if (isPageActive()) refreshAgainImmediately = true;
                return;
            }
            healthAvailable = false;
            const reason = requestTimedOut ? "Health endpoint request timed out." : error.message;
            cards.forEach(card => {
                const link = card.querySelector(".service-link");
                const monitored = isMonitoredLink(link);
                if (monitored) setCardStatus(card, "unknown", `Could not read server health data: ${reason}`);
            });
        } finally {
            if (requestTimeout !== null) window.clearTimeout(requestTimeout);
            requestTimeout = null;
            activeRequest = null;
            refreshInProgress = false;
            const refreshImmediately = refreshAgainImmediately;
            refreshAgainImmediately = false;
            refreshAbortedForPause = false;
            if (refreshImmediately && isPageActive()) refreshHealth();
            else scheduleRefresh();
        }
        updateSummary();
    }

    document.addEventListener("visibilitychange", syncRefreshState);
    window.addEventListener("focus", syncRefreshState);
    window.addEventListener("blur", pauseRefresh);
    syncRefreshState();
});
