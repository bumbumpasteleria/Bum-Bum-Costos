export function trustedDownload(value){try{const u=new URL(value);return u.protocol==='https:'&&u.hostname==='github.com'&&!u.username&&!u.password&&!u.port&&!u.search&&!u.hash&&/^\/bumbumpasteleria\/Bum-Bum-Costos\/releases\/download\/[A-Za-z0-9._-]+\/[A-Za-z0-9._-]+\.apk$/.test(u.pathname);}catch{return false}}
export function availableUpdate(manifest,current){
 if(!manifest||manifest.appId!=='com.bumbumpasteleria.costos'||!Number.isSafeInteger(manifest.versionCode)||manifest.versionCode<=0||!/^\d+\.\d+\.\d+$/.test(manifest.version)||!trustedDownload(manifest.downloadUrl))return null;
 const code=Number(current);if(!Number.isSafeInteger(code)||manifest.versionCode<=code)return null;
 return {version:manifest.version,downloadUrl:manifest.downloadUrl};
}
