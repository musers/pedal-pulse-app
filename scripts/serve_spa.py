import http.server
import socketserver
import os

PORT = 8080
DIRECTORY = "build/web"

class SPARequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        # Check if the requested path corresponds to a real file
        path = self.translate_path(self.path)
        if not os.path.exists(path) or os.path.isdir(path):
            # If not a physical file, serve index.html (SPA Single Page Application route)
            self.path = "/index.html"
        return super().do_GET()

if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), SPARequestHandler) as httpd:
        print(f"🚀 VeloRide SPA Server running at http://localhost:{PORT}")
        print(f"   • Explore Screen: http://localhost:{PORT}")
        print(f"   • Admin Portal:   http://localhost:{PORT}/admin")
        print(f"   • Wallet Screen:  http://localhost:{PORT}/wallet")
        httpd.serve_forever()
