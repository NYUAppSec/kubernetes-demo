FROM python:3.12-alpine
LABEL description="Backend API microservice"
WORKDIR /app
COPY server.py .
ENV PORT=5000
EXPOSE 5000
CMD ["python", "server.py"]
