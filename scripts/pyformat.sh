autoflake --in-place --remove-unused-variables --remove-all-unused-imports .
isort .
black .
flake8 .
