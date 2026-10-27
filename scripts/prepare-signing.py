"""Register this app and create its provisioning profile; reuse installed certificate.
Requires PyJWT, cryptography and requests. No secrets are written to the repository.
Usage: ASC_API_KEY_JSON=/private/key.json python3 scripts/prepare-signing.py
"""
import base64, json, os, plistlib, subprocess, time
from pathlib import Path
import jwt, requests

creds = json.loads(Path(os.environ['ASC_API_KEY_JSON']).read_text())
key = creds.get('key') or Path(creds['key_filepath']).read_text()
root = 'https://api.appstoreconnect.apple.com/v1/'
def api(method, resource, data=None, params=None):
    now = int(time.time())
    token = jwt.encode({'iss':creds['issuer_id'],'iat':now-20,'exp':now+1100,'aud':'appstoreconnect-v1'},key,algorithm='ES256',headers={'kid':creds['key_id']})
    r = requests.request(method,root+resource,headers={'Authorization':'Bearer '+token},json=data,params=params,timeout=60)
    if r.status_code >= 400:
        errors = r.json().get('errors',[])
        raise RuntimeError('; '.join(x.get('code','')+': '+x.get('detail','') for x in errors))
    return r.json()['data'] if r.content else None

bundle = api('GET','bundleIds',params={'filter[identifier]':'com.debbrecht.pvkompass'})
if not bundle:
    bundle = [api('POST','bundleIds',{'data':{'type':'bundleIds','attributes':{'identifier':'com.debbrecht.pvkompass','name':'PV Kompass','platform':'IOS'}}})]
bundle = bundle[0]
certificates = api('GET','certificates',params={'limit':100})
# Match installed distribution certificate by SHA-1 fingerprint, not just its display name.
identities = subprocess.check_output(['security','find-identity','-v','-p','codesigning'],text=True)
from cryptography import x509
from cryptography.hazmat.primitives import hashes
certs = []
for cert in certificates:
    if cert['attributes']['certificateType'] not in ['DISTRIBUTION','IOS_DISTRIBUTION']:
        continue
    der = base64.b64decode(cert['attributes']['certificateContent'])
    fingerprint = x509.load_der_x509_certificate(der).fingerprint(hashes.SHA1()).hex().upper()
    if fingerprint in identities: certs.append(cert)
if not certs: raise RuntimeError('No installed, valid App Store distribution identity matches Apple certificates. No new certificate was created.')
profiles = api('GET','profiles',params={'filter[name]':'PV Kompass App Store','include':'bundleId','limit':100})
profile = next((p for p in profiles if p['attributes']['profileState']=='ACTIVE' and p['relationships']['bundleId']['data']['id']==bundle['id']),None)
if profile is None:
    profile = api('POST','profiles',{'data':{'type':'profiles','attributes':{'name':'PV Kompass App Store','profileType':'IOS_APP_STORE'},'relationships':{'bundleId':{'data':{'type':'bundleIds','id':bundle['id']}},'certificates':{'data':[{'type':'certificates','id':certs[0]['id']}]}}}})
raw = base64.b64decode(profile['attributes']['profileContent'])
folder = Path.home()/'Library/Developer/Xcode/UserData/Provisioning Profiles'
folder.mkdir(parents=True,exist_ok=True)
path = folder/(profile['attributes']['uuid']+'.mobileprovision')
path.write_bytes(raw)
path.chmod(0o600)
print('Bundle ID registered and App Store profile installed:',profile['attributes']['name'])
apps = api('GET','apps',params={'filter[bundleId]':'com.debbrecht.pvkompass'})
if apps:
    print('App Store Connect app:',apps[0]['id'])
else:
    print('App record still needs creating in App Store Connect: iOS, PV Kompass, de-DE, SKU pvkompass-ios, bundle ID com.debbrecht.pvkompass')
