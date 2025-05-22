autoflake --in-place --remove-all-unused-imports --remove-unused-variables --remove-duplicate-keys -r .

isort . --profile black

black .

flake8 . --exclude='node_modules,.venv,__pycache__' --ignore=E203,E501,W503
