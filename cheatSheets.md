# Cheat Sheet
### Ethan Jansen
### 09/23/2024

## Hyprland
* Exit: `M`
* Launch programs:
    * Kitty: `q`

## Package Management
* List local packages: `pikaur -Qn`
* List foreign (AUR) packages: `pikaur -Qqm`
* List unused dependencies: `pikaur -Qdtq`
* Remove packages and its unused dependencies: `pikaur -Rs`
* Find packages requiring \<packages\>: `pikaur -Qi <package> | grep Required`

## Neovim
* Navigation: `hjkl`
* Exiting:
    * Discarding changes: `:q!`
    * Saving changes: `:wq`
* Write file: `:w`
* Editing text:
    * Delete: `x`
    * Insert: `i`
    * Append to word: `a`
    * Append after the line: `A`
    * Insert new line above: `o`
    * Insert new line below: `O`
    * Replace character: `r`
    * Replace mode: `R`
* Delete operator: `d`
    * Whole line: `dd`
    * Change (delete and place in insert mode): `c`
* Useful "Motions":
    * Until start of next word: `w`
    * To end of current word: `e`
    * To end of line: `$`
    * To start of line: `0`
* Undo:
    * Undo 1: `u`
    * Undo all on line: `U`
    * Redo: `<C-r>`
* Put/Paste:
    * After cursor: `p`
    * Before cursor: `P`
* Yank/Copy: `y`
    * Whole line: `yy`
* "Go":
    * Go to bottom of file: `G`
    * Go to top of file: `gg`
    * Go to line ##: `##G`
    * Go back to where came from: `<C-o>`
    * Go forward to where came from `<C-i>`
* Search mode:
    * Forward: `/`
    * Backwards: `?`
    * Ignore case: add `\c` to end of command
    * Next search: `n`
    * Previous search: `N`
    * Matching (),{},[]: `%`
* Substitute (like sed):
    * First occurrence: `:s/old/new/`
    * Globally in line: `:s/old/new/g`
    * From line # to #: `:#,#s/old/new/g`
    * Whole file: `:%s/old/new/g`
        * With prompt: `:%s/old/new/gc`
* Execute external command: `:!{command}`
* Visual selection: `v`
* Retrieve content and place at cursor: `:r {file/!command}`
* Navigate between windows: `<C-w><C-w>`
* List commands for command completion: `<C-d>`

## mpv
* Change tracks:
    * Subtitles: `j`
    * Audio: `#` 

## nnn
* Display preview: `;p`
* Batch rename: `r`

## Kitty
* Default modifier "kitty_mod": `ctrl+shift`
* New split window: `kitty_mod+enter`
* Close split window: `kitty_mod+d`
* Resize split: `kitty_mod+` left, right, down, up
* Change between horizonal/vertical split: `kitty_mod+r`
