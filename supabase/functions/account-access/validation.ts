export function validateRequest(input: Record<string,unknown>){
 const limits:Record<string,number>={email:254,ownerName:120,businessName:160,location:300,description:2000,businessType:80,phone:40,website:300};
 const data:Record<string,string>={};
 for(const [key,max] of Object.entries(limits)){const value=String(input[key]??'').trim();if(value.length>max)throw new Error('Revisa la longitud de los campos.');data[key]=value;}
 data.email=data.email.toLowerCase();
 if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email)||!data.ownerName||!data.businessName||!data.location)throw new Error('Completa correo, nombre del dueño, negocio y ubicación.');
 return data;
}
