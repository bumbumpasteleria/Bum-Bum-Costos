import {writeFile} from 'node:fs/promises';
import {MODULE_GUIDES} from '../src/features/help/guides.mjs';
const sections=Object.entries(MODULE_GUIDES).map(([name,guide])=>`## ${name}\n\n${guide.title}\n\n${guide.steps.map((step,index)=>`${index+1}. ${step}`).join('\n')}\n\n**Ejemplo:** ${guide.example}\n\n**Consejo:** ${guide.tip}\n`);
await writeFile(new URL('../docs/GUIA_DE_USO.md',import.meta.url),'# Guía de uso de Bum Bum Costos\n\nAbre «¿Cómo se usa?» en cada pantalla. Cada cuenta tiene su propio espacio.\n\n'+sections.join('\n'));
