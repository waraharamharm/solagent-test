"""Remove secrets and identifying data from text before it is indexed or published.

Everything the knowledge base serves goes to every client, so this runs on every file,
on every path, and a second pass (`find_leaks`) must come back empty or the build fails.
"""

import ipaddress
import json
import re
from dataclasses import dataclass, field
from pathlib import Path

REDACTED = "REDACTED"

_PEM = re.compile(
    r"-----BEGIN [A-Z0-9 ]*PRIVATE KEY(?: BLOCK)?-----.*?(?:-----END [A-Z0-9 ]*PRIVATE KEY(?: BLOCK)?-----|\Z)",
    re.DOTALL,
)

_KEY = r"[\w.-]*(?:pass(?:word|wd)?|pwd|secret|token|api[_-]?key|private[_-]?key|credential)[\w.-]*"
_ASSIGN = re.compile(
    rf"(?P<head>(?<![\w.-])(?P<key>{_KEY})(?:[\"']?\s*[=:]\s*|\s+))"
    r"(?P<val>'[^'\n]*'|\"[^\"\n]*\"|[A-Za-z0-9_!@#%^*+\-/=.~?]{6,})",
    re.IGNORECASE,
)
_PLACEHOLDER_START = ("$", "<", "{", "…", "...", "%", "/", "./", "~", "[", "(")
_PLACEHOLDER_WORDS = re.compile(
    r"^(?:change[_-]?me|changeme|your[_-]|example|placeholder|xxx+|\*+|none|null|true|false|redacted)",
    re.IGNORECASE,
)
_PATHLIKE_KEY = re.compile(r"(?:_|-)(?:file|path|dir|name|url|len|length|ttl|expiry|enabled)$", re.IGNORECASE)

_URL_CREDS = re.compile(r"(\b[a-z][a-z0-9+.-]*://)([^/\s:@'\"]+):([^@\s/'\"]+)@", re.IGNORECASE)
_MYSQL_P = re.compile(r"(\b(?:mysql|mariadb|mysqldump|mysqladmin)\b[^\n]*?\s-p)(\S+)")
_TOKENS = re.compile(
    r"\bgh[pousr]_[A-Za-z0-9]{30,}\b"
    r"|\bAIza[0-9A-Za-z_-]{30,}"
    r"|\bsk-[A-Za-z0-9_-]{20,}"
    r"|\bxox[baprs]-[A-Za-z0-9-]{10,}"
    r"|\bAKIA[0-9A-Z]{16}\b"
    r"|\beyJ[\w-]{10,}\.[\w-]{10,}\.[\w-]{10,}"
    r"|(?i:\bbearer)\s+[A-Za-z0-9._~+/=-]{20,}"
)

_MD5_LINE = re.compile(r"^[^\n]*md5[^\n]*$", re.IGNORECASE | re.MULTILINE)
_HEX32 = re.compile(r"\b[0-9a-fA-F]{32}\b")
_IDENTIFIED = re.compile(r"(\bidentified\s+(?:with\s+\w+\s+)?by\s+)('[^'\n]+'|\"[^\"\n]+\")", re.IGNORECASE)
_NOT_AN_IP = re.compile(r"(?:section|sect\.?|§|rfc|version|ver\.?|\bv)\s*$", re.IGNORECASE)

_SSH_LOGIN = re.compile(
    r"(\b(?:ssh|scp|rsync|sftp)\b[^\n]*?[\s'\"])(?!root@|USER@)([A-Za-z_][\w.-]*)@(?=[\w.-])", re.IGNORECASE
)

_EMAIL = re.compile(r"(?<![\w.+:-])[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
_IPV4 = re.compile(r"(?<![\w.])(?:\d{1,3}\.){3}\d{1,3}(?![\w]|\.\d)")
_HOME = re.compile(r"(/home/|/Users/|[A-Za-z]:\\Users\\)([^/\\\s'\"]+)")

_KEEP_NETS = [ipaddress.ip_network(n) for n in ("127.0.0.0/8", "0.0.0.0/8", "255.0.0.0/8", "169.254.0.0/16")]
_OUT_PUBLIC = ipaddress.ip_network("203.0.113.0/24")
_OUT_PRIVATE = ipaddress.ip_network("198.51.100.0/24")
_GENERIC_USERS = {"user", "username", "USER", "<user>", "%USERNAME%", "$USER", "root", "me"}


class ScrubError(Exception):
    pass


@dataclass
class Scrubber:
    """`literals` maps exact strings (domains, server nicknames, org names) to placeholders.

    They come from a local file, not from code: the real values must not live in this repo."""

    literals: dict[str, str] = field(default_factory=dict)
    ip_map: dict[str, str] = field(default_factory=dict)

    def __post_init__(self) -> None:
        ordered = sorted(self.literals, key=len, reverse=True)
        # Short literals ("x.com") must not match inside other words ("linux.com").
        parts = [("(?<![A-Za-z0-9])" if len(k) <= 5 else "") + re.escape(k) for k in ordered]
        self._literal_re = re.compile("|".join(parts), re.IGNORECASE) if ordered else None
        self._lower = {k.lower(): v for k, v in self.literals.items()}

    @classmethod
    def from_file(cls, path: Path) -> "Scrubber":
        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, dict) or not all(isinstance(v, str) for v in data.values()):
            raise ScrubError("literals file must be a JSON object of string to string")
        return cls(literals=data)

    def scrub_path(self, rel_path: str) -> str:
        return self._apply_literals(rel_path)

    def scrub(self, text: str) -> str:
        text = self._apply_literals(text)
        text = _PEM.sub("[REDACTED PRIVATE KEY]", text)
        text = _TOKENS.sub(REDACTED, text)
        text = _URL_CREDS.sub(rf"\1user:{REDACTED}@", text)
        text = _MYSQL_P.sub(rf"\1{REDACTED}", text)
        text = _ASSIGN.sub(self._assign, text)
        text = _IDENTIFIED.sub(self._identified, text)
        text = _MD5_LINE.sub(lambda m: _HEX32.sub(REDACTED, m.group(0)), text)
        text = _SSH_LOGIN.sub(r"\1USER@", text)
        text = _HOME.sub(self._home, text)
        text = _EMAIL.sub(lambda m: self._email(text, m), text)
        return _IPV4.sub(self._ip, text)

    def find_leaks(self, scrubbed: str, rel_path: str = "") -> list[str]:
        """Descriptions only: never the matched text."""
        leaks: list[str] = []
        for what, value in (("path", rel_path), ("content", scrubbed)):
            if self._literal_re and self._literal_re.search(value):
                leaks.append(f"{what}: configured literal still present")
        if self.scrub(scrubbed) != scrubbed:
            leaks.append("content: second scrub pass changed the text")
        if "PRIVATE KEY-----" in scrubbed and "[REDACTED PRIVATE KEY]" not in scrubbed:
            leaks.append("content: private key marker")
        return leaks

    def _apply_literals(self, text: str) -> str:
        if self._literal_re is None:
            return text
        def replace(m: re.Match[str]) -> str:
            new = self._lower[m.group(0).lower()]
            return new.upper() if m.group(0).isupper() else new

        return self._literal_re.sub(replace, text)

    def _assign(self, m: re.Match[str]) -> str:
        val = m.group("val")
        inner = val[1:-1] if val[0] in "'\"" else val
        if not self._is_secret_value(m.group("key"), inner, quoted=val[0] in "'\""):
            return m.group(0)
        quote = val[0] if val[0] in "'\"" else ""
        return f"{m.group('head')}{quote}{REDACTED}{quote}"

    def _identified(self, m: re.Match[str]) -> str:
        val = m.group(2)
        if not self._is_secret_value("password", val[1:-1], quoted=True):
            return m.group(0)
        return f"{m.group(1)}{val[0]}{REDACTED}{val[0]}"

    @staticmethod
    def _is_secret_value(key: str, value: str, *, quoted: bool) -> bool:
        if not value or value == REDACTED or _PATHLIKE_KEY.search(key):
            return False
        if value.startswith(_PLACEHOLDER_START) or "${" in value or _PLACEHOLDER_WORDS.match(value):
            return False
        if quoted:
            return True
        return any(c.isdigit() for c in value) and any(c.isalpha() for c in value)

    @staticmethod
    def _home(m: re.Match[str]) -> str:
        return m.group(0) if m.group(2) in _GENERIC_USERS else f"{m.group(1)}USER"

    @staticmethod
    def _email(text: str, m: re.Match[str]) -> str:
        if text[max(0, m.start() - 5) : m.start()].lower().endswith(("sip:", "sips:")):
            return m.group(0)
        if "example" in m.group(0).split("@", 1)[1].lower():
            return m.group(0)
        return "user@example.com"

    def _ip(self, m: re.Match[str]) -> str:
        raw = m.group(0)
        if _NOT_AN_IP.search(m.string[max(0, m.start() - 12) : m.start()]):
            return raw
        try:
            ip = ipaddress.IPv4Address(raw)
        except ValueError:
            return raw
        if any(ip in net for net in _KEEP_NETS) or ip in _OUT_PUBLIC or ip in _OUT_PRIVATE:
            return raw
        if raw not in self.ip_map:
            net = _OUT_PRIVATE if ip.is_private else _OUT_PUBLIC
            used = sum(1 for v in self.ip_map.values() if ipaddress.IPv4Address(v) in net)
            if used >= 253:
                raise ScrubError("too many distinct IP addresses to anonymize")
            self.ip_map[raw] = str(net.network_address + used + 1)
        return self.ip_map[raw]
