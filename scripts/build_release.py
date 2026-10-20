"""Build explicitly allowlisted project and skill archives; Python 3.11+."""
from hashlib import sha256
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]
VERSION = '0.1.0-preview.1'
SKILL = Path('plugins/default-browser/skills/default-browser')
PROJECT_FILES = [
    Path('.gitignore'), Path('.agents/plugins/marketplace.json'),
    Path('README.md'), Path('README.en.md'), Path('CHANGELOG.md'), Path('RELEASE_NOTES.md'),
    Path('Enable.cmd'), Path('Status.cmd'), Path('Restore.cmd'),
    Path('plugins/default-browser/plugin.json'),
    Path('plugins/default-browser/assets/external-browser.svg'),
    SKILL / 'SKILL.md', SKILL / 'scripts/Set-CodexLinkTarget.ps1',
    Path('tests/test_integration.py'), Path('scripts/build_release.py'),
]


def build():
    output = ROOT / 'dist'
    output.mkdir(exist_ok=True)
    project = output / f'chatgpt-default-browser-windows-v{VERSION}.zip'
    skill = output / f'default-browser-skill-v{VERSION}.zip'
    for file in PROJECT_FILES:
        if not (ROOT / file).is_file():
            raise FileNotFoundError(file)
    with ZipFile(project, 'w', compression=ZIP_DEFLATED) as archive:
        for file in PROJECT_FILES:
            archive.write(ROOT / file, Path(f'chatgpt-default-browser-{VERSION}') / file)
    with ZipFile(skill, 'w', compression=ZIP_DEFLATED) as archive:
        for file in [SKILL / 'SKILL.md', SKILL / 'scripts/Set-CodexLinkTarget.ps1']:
            archive.write(ROOT / file, Path('default-browser') / file.relative_to(SKILL))
    checksums = []
    for file in [project, skill]:
        with ZipFile(file) as archive:
            if archive.testzip() is not None:
                raise ValueError(f'Invalid ZIP: {file.name}')
            assert all('..' not in Path(name).parts for name in archive.namelist())
        checksums.append(f'{sha256(file.read_bytes()).hexdigest()}  {file.name}')
        print(f'{file.name}: {file.stat().st_size} bytes')
    (output / 'SHA256SUMS.txt').write_text('\n'.join(checksums) + '\n', encoding='utf-8')
    print('ZIP integrity and explicit file lists verified; SHA256SUMS.txt written.')


if __name__ == '__main__':
    build()
