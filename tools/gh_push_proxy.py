
# -*- coding: utf-8 -*-
"""GitHub 推送兜底：本地 CONNECT 代理（DNS 被污染时用）。

本机症状（2026-09-24 实测）：github.com 的 DNS 解析失败——
    curl https://github.com            -> 000（连不上）
    curl --resolve github.com:443:140.82.113.4 https://github.com -> 200
但 Clash 代理（127.0.0.1:7897）经常没开，所以需要这条兜底路径：
把域名直接解析到**可达 IP**，由本地代理转发。

用法：
    python tools/gh_push_proxy.py --port 7899 &         # 起代理（自动挑一个可达 IP）
    git -c http.proxy=http://127.0.0.1:7899 push origin main
    kill %1                                            # 推完关掉

    python tools/gh_push_proxy.py --probe              # 只探测哪些候选 IP 可达，不起代理
"""
import argparse
import http.client
import select
import socket
import socketserver
import ssl
import sys
import threading

# GitHub 常见边缘 IP（会轮换；--probe 可先筛一遍）
CANDIDATES = ["140.82.113.4", "20.27.177.113", "140.82.112.4", "20.205.243.166",
              "140.82.114.4", "140.82.121.4"]
HOST = "github.com"


def probe(ip, timeout=6.0):
    """连到该 IP 的 443 并用真实域名做 TLS 校验，返回 HTTP 状态码或 None。"""
    ctx = ssl.create_default_context()
    try:
        with socket.create_connection((ip, 443), timeout) as raw:
            with ctx.wrap_socket(raw, server_hostname=HOST) as tls:
                tls.sendall(b"HEAD / HTTP/1.1\r\nHost: " + HOST.encode() +
                            b"\r\nConnection: close\r\nUser-Agent: probe\r\n\r\n")
                data = tls.recv(128)
        first = data.split(b"\r\n", 1)[0].decode("latin-1", "replace")
        parts = first.split()
        return int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else None
    except Exception:
        return None


def pick_ip(explicit=None, timeout=6.0):
    if explicit:
        code = probe(explicit, timeout)
        print("probe %s -> %s" % (explicit, code))
        return explicit if code and code < 400 else None
    for ip in CANDIDATES:
        code = probe(ip, timeout)
        print("probe %-16s -> %s" % (ip, code))
        if code and code < 400:
            return ip
    return None


class Handler(socketserver.BaseRequestHandler):
    target = None

    def handle(self):
        conn = self.request
        conn.settimeout(30)
        buf = b""
        while b"\r\n\r\n" not in buf:
            chunk = conn.recv(4096)
            if not chunk:
                return
            buf += chunk
        line = buf.split(b"\r\n", 1)[0].decode("latin-1", "replace")
        if not line.upper().startswith("CONNECT"):
            conn.sendall(b"HTTP/1.1 405 Method Not Allowed\r\n\r\n")
            return
        try:
            _, authority, _ = line.split()
            _, port = authority.rsplit(":", 1)
        except ValueError:
            conn.sendall(b"HTTP/1.1 400 Bad Request\r\n\r\n")
            return
        try:
            up = socket.create_connection((self.target, int(port)), 15)
        except OSError:
            conn.sendall(b"HTTP/1.1 502 Bad Gateway\r\n\r\n")
            return
        conn.sendall(b"HTTP/1.1 200 Connection Established\r\n\r\n")
        up.settimeout(30)
        self._pump(conn, up)

    def _pump(self, a, b):
        socks = [a, b]
        try:
            while True:
                readable, _, _ = select.select(socks, [], [], 60)
                if not readable:
                    return
                for s in readable:
                    data = s.recv(65536)
                    if not data:
                        return
                    (b if s is a else a).sendall(data)
        except OSError:
            return
        finally:
            for s in socks:
                try:
                    s.close()
                except OSError:
                    pass


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=7899)
    ap.add_argument("--ip", help="手动指定转发到的 IP（默认自动挑可达的）")
    ap.add_argument("--probe", action="store_true", help="只探测候选 IP，不起代理")
    args = ap.parse_args()

    ip = pick_ip(args.ip)
    if not ip:
        print("PUSH-PROXY FAIL: 没有可达的 GitHub IP（网络整体不通）")
        return 1
    if args.probe:
        print("PUSH-PROXY OK: 可用 IP = %s" % ip)
        return 0

    Handler.target = ip
    with Server(("127.0.0.1", args.port), Handler) as srv:
        print("PUSH-PROXY OK: 127.0.0.1:%d -> %s:443（Ctrl+C 结束）" % (args.port, ip), flush=True)
        try:
            srv.serve_forever()
        except KeyboardInterrupt:
            pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
