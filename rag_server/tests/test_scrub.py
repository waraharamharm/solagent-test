import pytest

from solrag.scrub import Scrubber, ScrubError


@pytest.fixture
def s():
    return Scrubber(literals={"example-corp.net": "sip.example.com", "mybox": "node1"})


def test_quoted_password_in_connection_string(s):
    out = s.scrub("soci-connection-string=db=app user=fs password='Xm!bc79?aA' host=127.0.0.1 port=3306")
    assert "Xm!bc79" not in out
    assert "password='REDACTED'" in out
    assert "host=127.0.0.1" in out


def test_env_style_assignments(s):
    out = s.scrub("LIME_FOREIGN_SHARED_SECRET=lab-fed-secret-2026\nDB_PASSWORD: hunter22x\n")
    assert "lab-fed" not in out and "hunter22" not in out


@pytest.mark.parametrize(
    "line",
    [
        "CHAT_DB_PASSWORD=change_me_conference",
        "CHAT_DB_PASSWORD=${PASS1}",
        'SECRETS_DIR="$DEPLOY/etc-secrets/x"',
        "password='…'",
        "password=<hash>",
        "def auth_header(realm: str, nonce: str, password: str, uri: str)",
        "PASSWORDS = sys.argv[1:] or []",
        "password=''",
        "ssl_key_file=/etc/ssl/private/key.pem",
        "PrivateTmp=true",
    ],
)
def test_placeholders_and_code_are_kept(s, line):
    assert s.scrub(line) == line


def test_pem_block_removed_even_if_truncated(s):
    pem = "-----BEGIN RSA PRIVATE KEY-----\nMIIEabc\ndef\n-----END RSA PRIVATE KEY-----"
    assert s.scrub(f"a\n{pem}\nb") == "a\n[REDACTED PRIVATE KEY]\nb"
    assert "MIIE" not in s.scrub("-----BEGIN PRIVATE KEY-----\nMIIEabc")


def test_public_certificate_is_not_touched(s):
    cert = "-----BEGIN CERTIFICATE-----\nMIIabc\n-----END CERTIFICATE-----"
    assert s.scrub(cert) == cert


@pytest.mark.parametrize(
    "secret",
    [
        "ghp_" + "a" * 36,
        "AIza" + "B" * 35,
        "sk-" + "c" * 30,
        "AKIA" + "D" * 16,
        "eyJhbGciOiJIUzI1.eyJzdWIiOiIxMjM0.SflKxwRJSMeKKF2QT4",
    ],
)
def test_known_token_formats(s, secret):
    assert secret not in s.scrub(f"key is {secret} ok")


def test_bearer_header(s):
    assert "abcdefghij" not in s.scrub("Authorization: Bearer abcdefghijklmnopqrstuvwxyz")


def test_url_credentials(s):
    out = s.scrub("git clone https://bob:p4ss@host.tld/repo.git")
    assert "bob" not in out and "p4ss" not in out and "host.tld/repo.git" in out


def test_mysql_command_line_password(s):
    out = s.scrub("mysql -u root -pS3cretPass -e 'select 1'")
    assert "S3cret" not in out
    assert s.scrub("ss -ltn -p 5060") == "ss -ltn -p 5060"


def test_ips_are_mapped_stably_and_keep_loopback(s):
    out = s.scrub("a 95.27.113.59 b 95.27.113.59 c 10.1.2.3 d 8.8.4.4 e 127.0.0.1 f 0.0.0.0")
    assert "95.27.113.59" not in out and "10.1.2.3" not in out
    assert out.count("203.0.113.1") == 2
    assert "198.51.100.1" in out
    assert "127.0.0.1" in out and "0.0.0.0" in out
    assert s.scrub("95.27.113.59") == "203.0.113.1"


def test_sql_identified_by_and_md5_hashes(s):
    out = s.scrub("CREATE USER 'a'@'localhost' IDENTIFIED BY 'Rea1Pass'; -- IDENTIFIED BY 'CHANGE_ME_DB'")
    assert "Rea1Pass" not in out and "'CHANGE_ME_DB'" in out
    row = "('lab.test', '100', '7c6f45f8d3a64b0e9a1c2d3e4f506172', 'MD5', 1)"
    assert "7c6f45" not in s.scrub(row)
    sha = "'a2ca5f1c8d3a64b0e9a1c2d3e4f506172'"
    assert s.scrub(f"sha {sha}") == f"sha {sha}"


def test_section_and_version_numbers_are_not_ips(s):
    assert s.scrub("see section 3.5.4.8 and RFC 1.2.3.4, v5.6.7.8") == "see section 3.5.4.8 and RFC 1.2.3.4, v5.6.7.8"


def test_ip_with_cidr_and_not_version_strings(s):
    assert s.scrub("allow 192.168.1.0/24;") == "allow 198.51.100.1/24;"
    assert s.scrub("version 1.2.3.4.5 and 999.1.1.1") == "version 1.2.3.4.5 and 999.1.1.1"


def test_ip_overflow_fails_loudly():
    s = Scrubber()
    with pytest.raises(ScrubError):
        s.scrub(" ".join(f"11.0.{i // 250}.{i % 250 + 1}" for i in range(300)))


def test_literals_apply_to_text_and_paths_case_insensitively(s):
    assert s.scrub("host Example-Corp.NET and MyBox") == "host sip.example.com and node1"
    assert s.scrub_path("deploy/install-on-mybox.sh") == "deploy/install-on-node1.sh"


def test_short_literal_needs_word_boundary_and_case_is_kept():
    s = Scrubber(literals={"x.com": "lab.test", "mybox": "node1"})
    assert s.scrub("sip:1@x.com media-x.com linux.com") == "sip:1@lab.test media-lab.test linux.com"
    assert s.scrub("MYBOX_HOST") == "NODE1_HOST"


def test_emails_but_not_sip_uris(s):
    assert s.scrub("write to ivan.petrov@gmail.com") == "write to user@example.com"
    assert s.scrub("sip:100@sip.example.com") == "sip:100@sip.example.com"
    assert s.scrub("a@example.com") == "a@example.com"
    assert s.scrub("root@sip.example-voip.com") == "root@sip.example-voip.com"


def test_ssh_logins(s):
    out = s.scrub("scp -r d bob@host1:/tmp && ssh -i k alice@10.9.9.9 'ls' && rsync a carol@h:/x")
    assert "bob@" not in out and "alice@" not in out and "carol@" not in out
    assert s.scrub("ssh root@host1") == "ssh root@host1"
    assert s.scrub("sip:100@host1 and a mail to ssh-help@host.tld") == "sip:100@host1 and a mail to user@example.com"


def test_home_directories(s):
    assert s.scrub("/home/tim/app and C:\\Users\\tim\\x and /Users/tim/y") == (
        "/home/USER/app and C:\\Users\\USER\\x and /Users/USER/y"
    )
    assert s.scrub("/home/$USER/app") == "/home/$USER/app"


def test_scrub_is_idempotent(s):
    text = (
        "password='Zz9!qqqq' host=95.27.113.59 mail a@b.io /home/tim mybox\n"
        "-----BEGIN PRIVATE KEY-----\nAAAA\n-----END PRIVATE KEY-----\n"
    )
    once = s.scrub(text)
    assert s.scrub(once) == once


def test_find_leaks_reports_without_echoing(s):
    assert s.find_leaks(s.scrub("password='Zz9!qqqq' mybox")) == []
    leaks = s.find_leaks("still mybox here", "a/mybox.sh")
    assert any(leak.startswith("path") for leak in leaks)
    assert any(leak.startswith("content") for leak in leaks)
    assert all("mybox" not in leak for leak in leaks)
    assert s.find_leaks("password='Zz9!qqqq'")


def test_literals_file_validation(tmp_path):
    bad = tmp_path / "l.json"
    bad.write_text('["a"]', encoding="utf-8")
    with pytest.raises(ScrubError):
        Scrubber.from_file(bad)
    good = tmp_path / "g.json"
    good.write_text('{"a.test": "b.test"}', encoding="utf-8")
    assert Scrubber.from_file(good).scrub("A.test") == "b.test"
