document.addEventListener("DOMContentLoaded", () => {
    const host = location.hostname;
    const currentPort = location.port || (location.protocol === 'https:' ? '443' : '80');
    const currentFull = `${host}:${currentPort}`;
    const base = `${location.protocol}//${host}`;

    document.querySelectorAll(".service-link").forEach(link => {
        const {port} = link.dataset;
        if (port) {
            const fullUrl = `${base}:${port}`;
            link.href = fullUrl;

 /*           if (`${host}:${port}` === currentFull) {
                link.classList.add("current");
                const label = document.createElement("span");
                label.classList.add("ms-2", "fw-bold");
                label.textContent = " (текущий адрес)";
                link.appendChild(label);
            }
*/
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
