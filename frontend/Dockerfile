FROM nginx:alpine
LABEL description="Frontend web UI microservice"
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
