FROM python:3.9-buster as builder

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /usr/src

COPY poetry.lock pyproject.toml poetry.toml ./

RUN pip3 install poetry \
    && poetry install --no-dev


FROM python:3.9-slim-buster as runner

RUN apt-get update \
    && apt-get install -y libpq5 libxml2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -r -s /bin/false uvicornuser

WORKDIR /usr/src

COPY --from=builder /usr/src/.venv /usr/src/.venv

COPY src/app ./app

USER uvicornuser

EXPOSE 8000

CMD ["/usr/src/.venv/bin/gunicorn", "-w", "1", "-k", "uvicorn.workers.UvicornWorker", "--capture-output", "--log-level", "warning", "--access-logfile", "-", "--bind", ":8000", "app.main:app"]