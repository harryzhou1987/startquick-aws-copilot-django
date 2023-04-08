FROM python:3.11.2-bullseye

ENV ALLOWEDSOURCE="0.0.0.0"

WORKDIR /usr/src/app

COPY django-project/mysite .

# RUN apk update && apk add curl
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 80

RUN mkdir -p /opt/django
COPY entrypoint.sh /opt/django/entrypoint.sh
RUN chmod a+rx /opt/django/entrypoint.sh

ENTRYPOINT [ "/opt/django/entrypoint.sh" ]

CMD python manage.py runserver ${ALLOWEDSOURCE}:80