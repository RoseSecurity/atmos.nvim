if exists('g:loaded_atmos') | finish | endif
let g:loaded_atmos = 1

command! AtmosListStacks lua require('atmos').atmos_list_stacks_command()
command! AtmosListComponents lua require('atmos').atmos_list_components_command()
