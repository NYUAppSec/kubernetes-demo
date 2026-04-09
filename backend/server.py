from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os
import socket

class APIHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/info":
            data = {
                "service": "backend-api",
                "version": os.environ.get("APP_VERSION", "1.0"),
                "hostname": socket.gethostname(),
                "message": "Hello from the backend microservice!"
            }
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(json.dumps(data, indent=2).encode())
        elif self.path == "/healthz":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"ok")
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        print(f"[{self.date_time_string()}] {args[0]}")

if __name__ == "__main__":
    port = int(os.environ.get("PORT", "5000"))
    server = HTTPServer(("0.0.0.0", port), APIHandler)
    print(f"Backend API running on port {port}")
    server.serve_forever()
