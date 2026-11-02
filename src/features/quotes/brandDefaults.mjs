export function brandDefaults(user,profile={}){
 const bumBum=String(user?.email||'').trim().toLowerCase()==='bumbumpasteleria@gmail.com';
 return {bumBum,businessName:profile.business_name||(bumBum?'Bum Bum Pastelería':''),phone:profile.phone||'',location:profile.location||'',website:'',color:'#8a3450',logo:'',...(bumBum?{paper:'#fcf8f5',accent:'#f8e9ed'}:{})};
}
