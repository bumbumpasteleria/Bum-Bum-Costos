"""Prepare a private release keystore in the ephemeral CI runner; never log it."""
import base64
import json
import os
from pathlib import Path
import re

def prepare(config, directory):
    password=config.get('password','')
    alias=config.get('alias','')
    fingerprint=config.get('certificateSha256','').lower()
    if not re.fullmatch(r'[A-Za-z0-9_-]{24,128}',password) or not re.fullmatch(r'[a-z0-9-]{1,64}',alias) or not re.fullmatch(r'[a-f0-9]{64}',fingerprint):
        raise ValueError('Invalid signing configuration')
    data=base64.b64decode(config['keystore'],validate=True)
    if not 1000<=len(data)<=100000:
        raise ValueError('Invalid keystore size')
    target=Path(directory)/'bum-release.p12'
    with target.open('xb') as stream:
        stream.write(data)
    target.chmod(0o600)
    return {'BUM_KEYSTORE_PATH':str(target),'BUM_KEYSTORE_PASSWORD':password,'BUM_KEY_ALIAS':alias,'BUM_CERTIFICATE_SHA256':fingerprint}

if __name__=='__main__':
    try:
        values=prepare(json.loads(os.environ['ANDROID_SIGNING_CONFIG']),os.environ['RUNNER_TEMP'])
        print('::add-mask::'+values['BUM_KEYSTORE_PASSWORD'])
        with open(os.environ['GITHUB_ENV'],'a',encoding='utf-8') as stream:
            for key,value in values.items():
                stream.write(key+'='+value+'\n')
        print('Firma permanente preparada.')
    except Exception:
        raise SystemExit('No se pudo preparar la firma permanente. Revisa ANDROID_SIGNING_CONFIG.') from None
