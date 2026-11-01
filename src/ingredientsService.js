
import { supabase } from './supabase';

export async function obtenerIngredientes() {
  const { data, error } = await supabase
    .from('ingredients')
    .select('*')
    .order('name', { ascending: true });

  if (error) throw error;
  return data ?? [];
}

export async function guardarIngrediente({
  name,
  price,
  packageQty,
  unit
}) {
  const cantidad = Number(packageQty);
  const precio = Number(price);

  if (!name?.trim()) {
    throw new Error('Introduce el nombre del ingrediente.');
  }

  if (!['g', 'ml', 'unit'].includes(unit)) {
    throw new Error('Selecciona una unidad.');
  }

  if (!Number.isFinite(cantidad) || cantidad <= 0) {
    throw new Error('La cantidad debe ser mayor que cero.');
  }

  if (!Number.isFinite(precio) || precio < 0) {
    throw new Error('El precio no puede ser negativo.');
  }

  const costo = precio / cantidad;
  if (!Number.isFinite(costo) || costo >= 1e10 || (precio > 0 && costo < 0.0000005)) {
    throw new Error('El costo calculado está fuera del rango permitido.');
  }

  const { data, error } = await supabase
    .from('ingredients')
    .insert({
      name: name.trim(),
      base_unit: unit,
      last_unit_cost: costo,
      stock_quantity: cantidad,
      minimum_stock: 0
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

export function adaptarIngrediente(registro) {
  return {
    id: registro.id,
    stockQuantity: registro.stock_quantity == null ? null : Number(registro.stock_quantity),
    minimumStock: registro.minimum_stock == null ? null : Number(registro.minimum_stock),
    name: registro.name,
    supplier: registro.supplier || '',
    itemKind: registro.item_kind || 'ingredient',
    purchaseUnit: registro.purchase_unit || null,
    purchaseQuantity: registro.purchase_quantity == null ? null : Number(registro.purchase_quantity),
    purchasePrice: registro.purchase_price == null ? null : Number(registro.purchase_price),
    unit: registro.base_unit === 'unit' ? 'unidad' : registro.base_unit,
    // La cantidad de compra no está guardada en Supabase. Mostrar por unidad.
    packageQty: 1,
    price: registro.last_unit_cost == null ? null : Number(registro.last_unit_cost),
    lastUnitCost: registro.last_unit_cost == null ? null : Number(registro.last_unit_cost),
    cantidadCompraConfirmada: false
  };
}

export async function actualizarPrecioIngrediente({
  id,
  price,
  packageQty,
  unit
}) {
  const precio = Number(price);
  const cantidad = Number(packageQty);

  if (!Number.isFinite(precio) || precio < 0) {
    throw new Error('El precio debe ser un número válido.');
  }

  if (!Number.isFinite(cantidad) || cantidad <= 0) {
    throw new Error('La cantidad debe ser mayor que cero.');
  }

  const { data: ingrediente, error: consultaError } = await supabase
    .from('ingredients')
    .select('id, base_unit')
    .eq('id', id)
    .maybeSingle();
  if (consultaError) throw consultaError;
  if (!ingrediente) throw new Error('El ingrediente no existe en Supabase o no tienes acceso. Si es local, necesita migración.');
  if (ingrediente.base_unit !== (unit === 'unidad' ? 'unit' : unit)) throw new Error('La unidad cambió. Recarga antes de editar el precio.');
  const costo = precio / cantidad;
  if (!Number.isFinite(costo) || costo >= 1e10 || (precio > 0 && costo < 0.0000005)) {
    throw new Error('El costo calculado está fuera del rango permitido.');
  }

  const { data, error } = await supabase
    .from('ingredients')
    .update({
      last_unit_cost: costo
    })
    .eq('id', id)
    .eq('base_unit', ingrediente.base_unit)
    .select()
    .single();

  if (error) throw error;

  return data;
}

