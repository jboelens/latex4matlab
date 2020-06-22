# latex4matlab
MATLAB class that allows you to generate, view and compile LaTeX code from a MATLAB array.

This code was modified from the original latexTable function by Eli Duenisch, which can be found here:
https://github.com/eliduenisch/latexTable

What I changed:
	- The code is now a class definition, allowing you to modify settings after creating the object.
	- I added an extra method that generates code for the amsmath package's bmatrix environment, since I use it frequently.
	- I added support for symbolic variables, for easy inclusion of e.g. Jacobian matrices in your reports.
	- I added preview functionality, which largely runs outside MATLAB and creates a PNG image of whatever LaTeX object you are creating.
	- Added clickable buttons to copy LaTeX code or view the preview.
	
The 'tex' folder is where the preview .tex, .pdf and .png files are generated.
You can modify preview.tex if you wish, just make sure to leave the lines containing BEGIN PREVIEW and END PREVIEW.
The preview function in MATLAB uses these lines to identify where to put the generated code.
Please be aware that the preview function will attempt to run system commands on your computer.
This is necessary to compile the preview code and as far as I am aware should be completely harmless.

If you wish to use the preview function, make sure the following (free) software is installed:

• LaTeX compiler with the following packages:
  - standalone
  - amsmath
  - booktabs

If you are using MiKTeX, it should prompt you to install these packages automatically. See https://miktex.org/download

• ImageMagick (See https://imagemagick.org/script/download.php#windows). I use version 7.0.10
• GhostScript (See https://www.ghostscript.com/download/gsdnld.html). I use version 9.52

If all these are installed and verified to be working, you are good to
go!