autoflake --in-place --remove-unused-variables --remove-all-unused-imports -r .
isort .
black .
flake8 . --exclude node_modules --max-line-length=180
