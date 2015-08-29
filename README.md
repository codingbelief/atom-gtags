# Atom Gtags Package

Gtags for Atom  
This package uses [GNU GLOBAL](http://www.gnu.org/software/global/)

# Usage

1. Build gtags database (GTAGS, GPATH and GRTAGS) by `Build Gtags` context menu command of project root folders
2. After database builded, use the following hotkeys to get symbol definitions or references

  `alt-1` : Go to the definition of the symbol under cursor  
  `alt-2` : List the references of the symbol under cursor  
  `alt-3` : List all symbols of the file  
  `alt-4` : Look up symbol definition in the project  
  `alt-q` : Go backward  
  `alt-w` : Go forward  

3. When the file changed, gtags database will be updated on file saved automatically
4. You can also update the database manually by using `Update Gtags` of context menu command

# Know Issues
* atom-gtags is not working when there is whitespace in the file path.
