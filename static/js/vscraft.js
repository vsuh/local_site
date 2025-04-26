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
        }
    });

    const themeSwitcher = document.getElementById('themeSwitcher');

    function setInitialTheme() {
        const storedTheme = localStorage.getItem('theme');
        if (storedTheme === 'dark') {
            document.documentElement.setAttribute('data-bs-theme', 'dark');
            themeSwitcher.checked = true;
        } else {
            document.documentElement.removeAttribute('data-bs-theme');
            themeSwitcher.checked = false;
        }
    }

    function saveThemePreference(theme) {
        localStorage.setItem('theme', theme);
    }

    themeSwitcher.addEventListener('change', function () {
        if (this.checked) {
            document.documentElement.setAttribute('data-bs-theme', 'dark');
            saveThemePreference('dark');
        } else {
            document.documentElement.removeAttribute('data-bs-theme');
            saveThemePreference('');
        }
    });

    setInitialTheme();
});
