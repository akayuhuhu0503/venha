"""Preserve the pre-rebuild project and extract the user's authoritative package."""
from pathlib import Path
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[1]
archive = ROOT / '7150_PHONG_3D_SUA_LOI_DI_WC_v4.zip'
destination = ROOT / 'assets' / 'layout' / 'room_v4'
backup_dir = ROOT / '.history'
backup_dir.mkdir(exist_ok=True)
(backup_dir / '.gdignore').write_text('', encoding='utf-8')
backup = backup_dir / 'before_room_v05.zip'
if not backup.exists():
    files = []
    for folder in ['scripts', 'scenes', 'tests', 'assets/textures', 'assets/audio', 'build']:
        files.extend(p for p in (ROOT / folder).rglob('*') if p.is_file())
    files.extend(p for p in ROOT.iterdir() if p.is_file() and p.suffix in ['.godot', '.cfg', '.cmd', '.md'])
    files.extend(p for p in (ROOT / 'tools').glob('*.py'))
    with zipfile.ZipFile(backup, 'x', zipfile.ZIP_DEFLATED, compresslevel=3) as out:
        for path in files:
            out.write(path, path.relative_to(ROOT).as_posix())
    with zipfile.ZipFile(backup) as check:
        assert check.testzip() is None
    print('BACKUP', backup, len(files), 'files')
destination.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(archive) as source:
    for member in source.infolist():
        target = (destination / member.filename).resolve()
        assert target.is_relative_to(destination.resolve()), 'Unsafe archive path'
        if member.is_dir():
            target.mkdir(parents=True, exist_ok=True)
            continue
        payload = source.read(member)
        if target.exists():
            assert target.read_bytes() == payload, 'Existing source differs: ' + str(target)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(payload)
    print('EXTRACTED', len(source.infolist()), 'entries; original ZIP unchanged')
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
(destination / 'SOURCE_ARCHIVE.json').write_text(json.dumps({'archive': archive.name, 'sha256': digest}, indent=2), encoding='utf-8')
