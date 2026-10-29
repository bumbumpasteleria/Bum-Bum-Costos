
import { supabase } from './supabase';

export async function obtenerIngredientes() {
  const { data, error } = await supabase
    .from('ingredients')
    .select('*')
    .order('name', { ascending: true });

  if (error) throw error;
  return data;
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

  if (!Number.isFinite(cantidad) || cantidad <= 0) {
    throw new Error('La cantidad comprada debe ser mayor que cero.');
  }

  if (!Number.isFinite(precio) || precio < 0) {
    throw new Error('El precio no puede ser negativo.');
  }

  const { data, error } = await supabase
    .from('ingredients')
    .insert({
      name: name.trim(),
      base_unit: unit,
      last_unit_cost: precio / cantidad,
      stock_quantity: cantidad,
      minimum_stock: 0
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}
