import React from 'react';
import {coverFor} from './coverAssets.mjs';
export default function RecipeCover({recipe,info,hero=false}){
 const cover=coverFor(recipe,info);
 return <figure className={'recipe-cover'+(hero?' recipe-cover-hero':'')}><img src={cover.src} alt={cover.illustrative?'Referencia visual de repostería':('Foto de '+recipe.name)} loading={hero?'eager':'lazy'} decoding="async"/>{cover.illustrative&&<figcaption>Imagen de referencia</figcaption>}</figure>;
}

