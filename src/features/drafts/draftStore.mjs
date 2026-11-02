export const draftKey=(owner,scope)=>`bum-bum-draft:v1:${owner}:${scope}`;
export function readDraft(storage,owner,scope,fallback){
 if(!owner)return typeof fallback==='function'?fallback():fallback;
 try{const raw=storage.getItem(draftKey(owner,scope));if(raw!==null){const data=JSON.parse(raw);if(data.version===1&&data.value!=null)return data.value;}}catch{}
 return typeof fallback==='function'?fallback():fallback;
}
export function writeDraft(storage,owner,scope,value){
 if(!owner)return;
 storage.setItem(draftKey(owner,scope),JSON.stringify({version:1,value}));
}
