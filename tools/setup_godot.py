"""Fetch verified Godot portable engine and only Windows x64 export templates."""
import hashlib
import io
import json
from pathlib import Path
import struct
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parent
VERSION = "4.7.2-stable"
BASE = f"https://godot-releases.nbg1.your-objectstorage.com/{VERSION}/"
HEADERS = {"User-Agent": "VeNhaPrototypeSetup/1.0"}


def fetch(url, headers=None):
    return urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS | (headers or {})), timeout=120)


class RemoteZip(io.RawIOBase):
    def __init__(self, url, size):
        self.url, self.size, self.pos = url, size, 0

    def seekable(self):
        return True

    def seek(self, offset, whence=0):
        self.pos = offset if whence == 0 else self.pos + offset if whence == 1 else self.size + offset
        return self.pos

    def tell(self):
        return self.pos

    def read(self, n=-1):
        n = self.size - self.pos if n < 0 else min(n, self.size - self.pos)
        if n <= 0:
            return b""
        start = self.pos
        with fetch(self.url, {"Range": f"bytes={start}-{start+n-1}"}) as response:
            if response.status != 206:
                raise RuntimeError("Range response required; refusing full template download")
            data = response.read()
        if len(data) != n:
            raise RuntimeError(f"Range size mismatch {len(data)} != {n}")
        self.pos += n
        return data


def main():
    release = json.load(fetch(f"https://api.github.com/repos/godotengine/godot-builds/releases/tags/{VERSION}"))
    assets = {a["name"]: a for a in release["assets"]}
    engine_name = f"Godot_v{VERSION}_win64.exe.zip"
    asset = assets[engine_name]
    engine_dir = ROOT / "godot"
    engine_dir.mkdir(parents=True, exist_ok=True)
    archive = engine_dir / engine_name
    expected = asset["digest"].removeprefix("sha256:")
    if not archive.exists() or hashlib.sha256(archive.read_bytes()).hexdigest() != expected:
        print("Downloading engine", flush=True)
        with fetch(BASE + engine_name) as response, archive.open("wb") as output:
            while chunk := response.read(1024 * 1024):
                output.write(chunk)
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    if digest != expected:
        raise RuntimeError("Engine SHA256 mismatch")
    with zipfile.ZipFile(archive) as engine_zip:
        engine_zip.extractall(engine_dir)
    print("Engine verified and extracted", digest, flush=True)

    template_name = f"Godot_v{VERSION}_export_templates.tpz"
    template_dir = ROOT / "templates" / "4.7.2.stable"
    template_dir.mkdir(parents=True, exist_ok=True)
    template_records = []
    remote = RemoteZip(BASE + template_name, assets[template_name]["size"])
    with zipfile.ZipFile(remote) as template_zip:
        for name in ["templates/windows_release_x86_64.exe", "templates/windows_debug_x86_64.exe", "templates/version.txt"]:
            info = template_zip.getinfo(name)
            destination = template_dir / Path(name).name
            print("Extracting", name, "compressed bytes", info.compress_size, flush=True)
            data = template_zip.read(name)
            destination.write_bytes(data)
            template_records.append({"file": str(destination.relative_to(ROOT)), "sha256": hashlib.sha256(data).hexdigest(), "zip_crc32": hex(info.CRC), "size": len(data)})
    license_url = f"https://raw.githubusercontent.com/godotengine/godot/{VERSION}/LICENSE.txt"
    (engine_dir / "LICENSE.txt").write_bytes(fetch(license_url).read())
    (ROOT / "godot_sources.json").write_text(json.dumps({"version": VERSION, "engine_source": BASE + engine_name, "engine_sha256": digest, "engine_sha256_source": "GitHub release asset digest", "template_source": BASE + template_name, "template_validation": "Per-entry ZIP CRC32 verified by zipfile over HTTPS; full archive SHA256 not checked because only Windows entries downloaded", "templates": template_records, "license": "MIT", "license_source": license_url}, indent=2), encoding="utf-8")
    print("Setup complete", flush=True)


if __name__ == "__main__":
    main()
