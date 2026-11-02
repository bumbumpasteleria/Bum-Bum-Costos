import test from 'node:test';
import assert from 'node:assert/strict';
import {brandDefaults} from '../src/features/quotes/brandDefaults.mjs';
test('Solo la cuenta de Bum Bum recibe su identidad original y conserva preferencias guardadas',()=>{
 const own=brandDefaults({email:' BUMBUMPASTELERIA@gmail.com '},{});
 assert.equal(own.bumBum,true);assert.equal(own.color,'#8a3450');assert.equal(own.paper,'#fcf8f5');assert.equal(own.accent,'#f8e9ed');assert.equal(own.businessName,'Bum Bum Pastelería');
 const custom={...own,logo:'data:image/jpeg;base64,original',...{logo:'',color:'#225577'}};
 assert.equal(custom.logo,'');assert.equal(custom.color,'#225577');
 const other=brandDefaults({email:'otra@example.invalid'},{business_name:'Otro negocio'});
 assert.equal(other.bumBum,false);assert.equal(other.logo,'');assert.equal(other.paper,undefined);assert.equal(other.businessName,'Otro negocio');
});
