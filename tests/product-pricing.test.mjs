import test from 'node:test';import assert from 'node:assert/strict';
import {unitPrice,saleTotal} from '../src/features/stock/productPricing.mjs';
test('precios por unidad y cantidad generan importes redondeados a centavos',()=>{
 assert.equal(saleTotal(3,50),150);assert.equal(saleTotal(.5,'75.25'),37.63);assert.equal(saleTotal('1.005','10'),10.05);assert.equal(saleTotal(2,0),0);assert.equal(unitPrice('12,50'),12.5);
});
test('no se inventa precio cero ni se aceptan cantidades o precios fuera de precisión',()=>{
 for(const value of ['',null,undefined,-1,NaN,Infinity,'12.345','1e3',1e9])assert.throws(()=>unitPrice(value));
 for(const value of ['',null,0,-1,Infinity,.0001,1.1234])assert.throws(()=>saleTotal(value,50));
});
