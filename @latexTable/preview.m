function varargout = preview(obj)
% PREVIEW - The function takes a latexTable object as input, adds its
% generated LaTeX code to the preview.tex file and compiles and converts it to
% png. It then loads the png file in MATLAB and shows it in a new figure.


%% Get directory
texFileName = mfilename('fullpath');

classFolder = fileparts(texFileName);
latexTableFolder = fileparts(classFolder);

texFolder = [latexTableFolder,filesep,'tex'];

%% Read file and find preview lines
texFileName = [texFolder,filesep,'preview.tex'];
tex = fileread(texFileName);

% Filter newlines AND carriage returns (\r)
expr = ['[',newline,sprintf('\r'),']'];
lines = regexp(tex,expr,'split');

i1 = find(contains(lines,'BEGIN PREVIEW'));
i2 = find(contains(lines,'END PREVIEW'));

%% Build tex to write to file
tex2write = strjoin([lines(1:i1), {[newline,obj.Text,newline]}, lines(i2:end)],newline);

% Escape any special characters
tex2write = regexprep(tex2write,'\\','\\\');
tex2write = regexprep(tex2write,'\%','%%');

%% Write valid LaTeX to file
fID = fopen(texFileName,'W');
fprintf(fID,tex2write);
fclose(fID);

%% Compile tex file

% % Perform installation checks
[latexInstalled,latexVersion] = system('latex --version');

% Show just first line of whatever output is given
latexVersion = regexp(latexVersion,newline,'split');
latexVersion = latexVersion{1};

if latexInstalled ~= 0
    error('No valid LaTeX distribution found on your system');
else
    fprintf('Compiling with distribution:\n%s\n\n',latexVersion);
end

% Run system compiler
cdCommand = ['cd ',latexTableFolder,' & '];
command1 = 'pdflatex -interaction=nonstopmode -shell-escape -output-directory=tex tex/preview.tex';
[status1,output1] = system([cdCommand, command1]);

if status1 ~= 0
    error('LaTeX compilation failed. The following output was reported: \n%s',output1)
end

%% Convert to PNG

[magickInstalled,magickVersion] = system('magick -version');

% Show just first line of whatever output is given
magickVersion = regexp(magickVersion,newline,'split');
magickVersion = magickVersion{1};

if magickInstalled ~= 0
    warning('No valid ImageMagick installation found on your system. Opening PDF file.');
    open([texFolder,filesep,'preview.pdf'])
else
    fprintf('Converting with ImageMagick:\n%s\n\n',magickVersion);
end

% Run conversion
command2 = 'magick -density 600 tex/preview.pdf +profile "icc" tex/preview.png';
[status2,output2] = system([cdCommand, command2]);

if status2 ~= 0
    error('Conversion to PNG failed. The following output was reported: \n%s',output2)
end

figure(); clf();
im = imread([texFolder,filesep,'preview.png']);
image(im), colormap gray, axis equal, grid off
xlim([1,size(im,2)])
ylim([1,size(im,1)])

xticks([])
xticklabels([])

yticks([])
yticklabels([])

%% Return image if requested
if nargout
    varargout = {im};
end

end