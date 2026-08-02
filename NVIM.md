# Guia de Neovim (NvChad) - Moskov Environment v3.0

---

## Informacion General

- **Version:** Neovim 0.10.3 (instalado en /opt/nvim)
- **Framework:** NvChad (configuracion pre-armada sobre lazy.nvim)
- **Ruta config:** `~/.config/nvim/`
- **Leader key:** `Espacio`

---

## Abrir Neovim

```bash
nvim                    # Abrir sin archivo
nvim archivo.py         # Abrir archivo especifico
nvim .                  # Abrir explorador de archivos
```

---

## Modos

| Tecla | Modo | Descripcion |
|-------|------|-------------|
| `i` | Insert | Escribir texto |
| `Esc` o `jk` | Normal | Navegar y comandos |
| `v` | Visual | Seleccionar texto |
| `V` | Visual Line | Seleccionar lineas |
| `:` o `;` | Command | Ejecutar comandos |

---

## Navegacion Basica

| Tecla | Accion |
|-------|--------|
| `h j k l` | Izquierda, abajo, arriba, derecha |
| `w` | Siguiente palabra |
| `b` | Palabra anterior |
| `0` | Inicio de linea |
| `$` | Fin de linea |
| `gg` | Inicio del archivo |
| `G` | Fin del archivo |
| `Ctrl+d` | Bajar media pagina |
| `Ctrl+u` | Subir media pagina |
| `/{texto}` | Buscar texto |
| `n` / `N` | Siguiente/anterior resultado |

---

## Edicion

| Tecla | Accion |
|-------|--------|
| `i` | Insertar antes del cursor |
| `a` | Insertar despues del cursor |
| `o` | Nueva linea abajo |
| `O` | Nueva linea arriba |
| `dd` | Eliminar linea |
| `yy` | Copiar linea |
| `p` | Pegar despues |
| `P` | Pegar antes |
| `u` | Deshacer |
| `Ctrl+r` | Rehacer |
| `ciw` | Cambiar palabra actual |
| `di"` | Eliminar contenido entre comillas |
| `.` | Repetir ultima accion |

---

## NvChad - Atajos con Leader (Espacio)

### Archivos y Buffers

| Atajo | Accion |
|-------|--------|
| `Space + e` | Toggle explorador de archivos (NvimTree) |
| `Space + ff` | Buscar archivo (Telescope) |
| `Space + fw` | Buscar texto en archivos (grep) |
| `Space + fb` | Lista de buffers abiertos |
| `Space + fh` | Buscar en ayuda |
| `Space + fo` | Archivos recientes |
| `Space + x` | Cerrar buffer actual |
| `Tab` | Siguiente buffer |
| `Shift+Tab` | Buffer anterior |

### Ventanas (splits)

| Atajo | Accion |
|-------|--------|
| `Ctrl+h/j/k/l` | Navegar entre splits |
| `:vs` | Split vertical |
| `:sp` | Split horizontal |
| `Ctrl+w q` | Cerrar split |

### Terminal

| Atajo | Accion |
|-------|--------|
| `Space + h` | Terminal horizontal |
| `Space + v` | Terminal vertical |
| `Alt+h/v` | Toggle terminal |

### LSP (Autocompletado e Inteligencia)

| Atajo | Accion |
|-------|--------|
| `gd` | Ir a definicion |
| `K` | Ver documentacion (hover) |
| `Space + ra` | Renombrar simbolo |
| `Space + ca` | Code actions |
| `[d` / `]d` | Diagnostico anterior/siguiente |
| `Space + q` | Lista de diagnosticos |

### Git

| Atajo | Accion |
|-------|--------|
| `Space + cm` | Git commits |
| `Space + gt` | Git status |

---

## Comandos Utiles

```vim
:w                  " Guardar
:q                  " Salir
:wq                 " Guardar y salir
:q!                 " Salir sin guardar
:%s/viejo/nuevo/g   " Reemplazar en todo el archivo
:set number         " Mostrar numeros de linea
:set relativenumber " Numeros relativos
:NvCheatsheet       " Ver todos los atajos de NvChad
:Lazy               " Gestor de plugins
:Mason              " Gestor de LSP servers
:TSInstall python   " Instalar treesitter para lenguaje
```

---

## Plugins Incluidos

| Plugin | Funcion |
|--------|---------|
| **NvChad/base46** | Temas (40+ incluidos) |
| **nvim-telescope** | Busqueda fuzzy de archivos y texto |
| **nvim-tree** | Explorador de archivos lateral |
| **nvim-lspconfig** | Configuracion LSP |
| **conform.nvim** | Formateo de codigo |
| **lazy.nvim** | Gestor de plugins |
| **nvim-cmp** | Autocompletado |
| **treesitter** | Resaltado de sintaxis avanzado |

---

## Instalar Soporte para un Lenguaje

```vim
" 1. Instalar parser de sintaxis
:TSInstall python lua bash javascript go

" 2. Instalar LSP server
:Mason
" Buscar el servidor (pyright, lua_ls, bashls, tsserver, gopls)
" Presionar 'i' para instalar
```

---

## Cambiar Tema

```vim
:Telescope themes
" o
Space + th
```

---

## Estructura de Configuracion

```
~/.config/nvim/
├── init.lua              Punto de entrada
├── lazy-lock.json        Versiones de plugins
└── lua/
    ├── chadrc.lua        Config principal NvChad
    ├── mappings.lua      Atajos personalizados
    ├── options.lua       Opciones de vim
    ├── configs/
    │   ├── conform.lua   Formateo
    │   ├── lazy.lua      Config de lazy.nvim
    │   └── lspconfig.lua Servidores LSP
    └── plugins/
        └── init.lua      Lista de plugins
```

---

## Mappings Personalizados (este entorno)

| Atajo | Accion |
|-------|--------|
| `;` | Entra en modo comando (reemplaza `:`) |
| `jk` | Sale de modo Insert (reemplaza `Esc`) |

---

## Tips

- Usa `:NvCheatsheet` para ver TODOS los atajos de NvChad
- `Space + th` para cambiar tema en tiempo real
- `:Lazy update` para actualizar plugins
- `:Mason` para gestionar LSP, linters y formatters
- Los archivos se auto-guardan al salir del modo Insert si configuras conform con format-on-save
