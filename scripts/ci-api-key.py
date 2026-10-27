"""Prepare private Fastlane JSON from GitLab variables; never print key material."""
import json, os
from pathlib import Path
key = Path(os.environ['APP_STORE_CONNECT_API_KEY_PATH']).read_text()
p = Path('build/asc-api-key.json'); p.parent.mkdir(exist_ok=True)
p.write_text(json.dumps({'key_id':os.environ['APP_STORE_CONNECT_API_KEY_ID'], 'issuer_id':os.environ['APP_STORE_CONNECT_API_ISSUER_ID'], 'key':key, 'in_house':False}))
p.chmod(0o600)
