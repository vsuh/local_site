#!/bin/bash

# Конфигурация
HOOKS_DIR=".githooks"
VENV_DIR=".venv"
HOOK_FILE="$HOOKS_DIR/pre-commit"

# Создаем виртуальное окружение
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR" || exit 1
fi

# Активируем окружение
source "$VENV_DIR/bin/activate"

# Устанавливаем зависимости

    if ! "$VENV_DIR/bin/python" -c 'import jinja2' >/dev/null 2>&1; then
        echo 'Installing requirements...'
        "$VENV_DIR/bin/pip" install -r requirements.txt || exit 1
    fi


# Настраиваем hooksPath
echo "Configuring git hooks path..."
git config --unset core.hooksPath
git config --local core.hooksPath "$HOOKS_DIR" || exit 1

# Создаем директорию для хуков
mkdir -p "$HOOKS_DIR"

# Создаем файл хука
echo "Creating pre-commit hook..."
cat > "$HOOK_FILE" << 'EOL'
#!/bin/sh

# Проверяем изменения в исходных файлах
CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E 'src/(index\.tpl|site\.json)')

if [ -n "$CHANGED_FILES" ] || [ ! -f index.html ]; then
    echo 'Changes detected in template or config, generating index.html...'
    
    # Используем Python из виртуального окружения
    python src/generate.py || exit 1
    
    # Добавляем в индекс
    # git add index.html
fi

exit 0
EOL

# Устанавливаем права
chmod +x "$HOOK_FILE"

echo "Hook system configured successfully"
