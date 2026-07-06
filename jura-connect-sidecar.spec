# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['/Users/stan/Desktop/TheSTouch/ORMAES/StaGuiTho/tauri-v2-plugins/tauri-plugin-jura-connect/scripts/pyinstaller-entrypoint.py'],
    pathex=['.'],
    binaries=[],
    datas=[('jura_connect/data', 'jura_connect/data')],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='jura-connect-sidecar',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
